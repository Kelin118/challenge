import express from 'express';
import cors from 'cors';
import multer from 'multer';
import fs from 'fs/promises';
import OpenAI from 'openai';

import { env } from './config/env.js';
import authRoutes from './routes/authRoutes.js';
import challengeRoutes from './routes/challengeRoutes.js';
import achievementsRoutes from './routes/achievementsRoutes.js';
import { authMiddleware } from './middleware/authMiddleware.js';
import { verifyRateLimitMiddleware } from './middleware/rateLimit.js';
import { sendError, sendSuccess } from './utils/apiResponse.js';

const app = express();
const upload = multer({ dest: 'tmp/' });

const openAiClient = env.openAiApiKey
  ? new OpenAI({ apiKey: env.openAiApiKey })
  : null;

if (!env.openAiApiKey) {
  console.warn('OPENAI_API_KEY is not set. Verification endpoint will fail until it is configured.');
}

app.set('trust proxy', 1);

app.use(cors(buildCorsOptions()));
app.use(express.json({ limit: '10mb' }));

app.get('/health', (_, res) => {
  return sendSuccess(res, { status: 'ok' });
});

app.get('/api/health', (_, res) => {
  return sendSuccess(res, {
    status: 'ok',
    service: 'achievement-vault-backend',
    environment: env.nodeEnv,
  });
});

app.use('/api/auth', authRoutes);
app.use('/api', challengeRoutes);
app.use('/api', achievementsRoutes);

app.post(
  '/api/verify-achievement',
  authMiddleware,
  verifyRateLimitMiddleware,
  upload.single('proof'),
  async (req, res, next) => {
    const file = req.file;

    try {
      if (!file) {
        return sendError(res, 'Файл доказательства не передан.', 400, 'missing_file');
      }

      if (!openAiClient) {
        return sendError(res, 'OPENAI_API_KEY не настроен на backend.', 500, 'server_misconfigured');
      }

      const bytes = await fs.readFile(file.path);
      const base64 = bytes.toString('base64');

      const prompt = [
        'Ты проверяешь достижение в игровом мобильном приложении.',
        'Ответь только JSON: {"passed": true/false, "explanation": "короткое объяснение на русском"}',
        `Название достижения: ${req.body.title ?? ''}`,
        `Описание: ${req.body.description ?? ''}`,
        `Условие получения: ${req.body.unlockCondition ?? ''}`,
        `Тип доказательства: ${req.body.proofType ?? ''}`,
        'Проверь, является ли изображение достаточным подтверждением выполнения.',
        'Если подтверждение неочевидно, недостаточно или не по теме, верни passed=false.',
      ].join('\n');

      const response = await openAiClient.responses.create({
        model: 'gpt-4.1-mini',
        input: [
          {
            role: 'user',
            content: [
              { type: 'input_text', text: prompt },
              {
                type: 'input_image',
                image_url: `data:${file.mimetype};base64,${base64}`,
              },
            ],
          },
        ],
      });

      const outputText = extractOutputText(response);

      try {
        const parsed = JSON.parse(outputText);
        return sendSuccess(res, {
          passed: Boolean(parsed.passed),
          explanation: parsed.explanation || 'AI не вернул объяснение.',
        });
      } catch {
        return sendSuccess(res, {
          passed: false,
          explanation: outputText.trim().length > 0
            ? `AI вернул неожиданный ответ: ${outputText}`
            : 'AI не смог сформировать корректный ответ.',
        });
      }
    } catch (error) {
      return next(error);
    } finally {
      if (file) {
        await fs.unlink(file.path).catch(() => {});
      }
    }
  },
);

app.use((req, res) => {
  return sendError(res, `Маршрут ${req.method} ${req.originalUrl} не найден.`, 404, 'not_found');
});

app.use((error, _req, res, _next) => {
  console.error('Unhandled app error:', error);

  return sendError(
    res,
    error instanceof Error ? error.message : 'Внутренняя ошибка сервера.',
    500,
    'internal_error',
    env.nodeEnv === 'production'
      ? null
      : error instanceof Error
        ? error.stack
        : String(error),
  );
});

function buildCorsOptions() {
  if (env.corsOrigins.length === 0) {
    return {
      origin: true,
      credentials: true,
    };
  }

  return {
    origin(origin, callback) {
      if (!origin || env.corsOrigins.includes(origin)) {
        return callback(null, true);
      }

      return callback(new Error('CORS origin is not allowed.'));
    },
    credentials: true,
  };
}

function extractOutputText(response) {
  if (response.output_text) {
    return response.output_text;
  }

  for (const item of response.output ?? []) {
    for (const part of item.content ?? []) {
      if (part.type === 'output_text' && part.text) {
        return part.text;
      }
    }
  }

  return '';
}

export default app;

