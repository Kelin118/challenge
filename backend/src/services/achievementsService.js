import OpenAI from 'openai';

import { env } from '../config/env.js';
import { withTransaction } from '../db.js';
import {
  createMissingUserAchievement,
  ensureUserAchievementRows,
  getAllDefinitions,
  getStatsAggregate,
  getUserAchievementByKey,
  getUserAchievements,
  getUserStats,
  seedDefinitions,
  upsertUserStats,
  updateUserAchievementState,
} from '../repositories/achievementsRepository.js';
import { baseAchievementDefinitions } from './achievementSeed.js';

const openAiClient = env.openAiApiKey
  ? new OpenAI({ apiKey: env.openAiApiKey })
  : null;

function buildUnlockHint(targetValue) {
  if (targetValue <= 1) {
    return 'Выполни условие достижения.';
  }

  return `Набери ${targetValue} прогресса, чтобы открыть достижение.`;
}

function mapDefinition(row) {
  return {
    id: row.id ?? row.definition_id,
    key: row.key,
    title: row.title,
    description: row.description,
    category: row.category,
    rarity: row.rarity,
    icon: row.icon,
    coinReward: row.coin_reward,
    targetValue: row.target_value,
    isHidden: row.is_hidden,
    verificationType: row.verification_type,
    unlockHint: buildUnlockHint(Number(row.target_value)),
    createdAt: row.created_at ?? row.definition_created_at,
    updatedAt: row.updated_at ?? row.definition_updated_at,
  };
}

function mapAchievement(row) {
  return {
    definition: mapDefinition(row),
    state: {
      progress: Number(row.progress ?? 0),
      isUnlocked: Boolean(row.is_unlocked),
      unlockedAt: row.unlocked_at,
      verificationStatus: row.verification_status ?? 'none',
      lastEvidenceText: row.last_evidence_text,
      createdAt: row.user_created_at,
      updatedAt: row.user_updated_at,
    },
  };
}

async function recalculateStats(userId, db) {
  const aggregateResult = await getStatsAggregate(userId, db);
  const aggregate = aggregateResult.rows[0] ?? {
    total_coins: 0,
    unlocked_count: 0,
    achievements_count: 0,
  };

  const totalCoins = Number(aggregate.total_coins ?? 0);
  const unlockedCount = Number(aggregate.unlocked_count ?? 0);
  const achievementsCount = Number(aggregate.achievements_count ?? 0);

  const statsResult = await upsertUserStats(
    {
      userId,
      totalCoins,
      unlockedCount,
      achievementsCount,
    },
    db,
  );

  const stats = statsResult.rows[0];

  return {
    userId: stats.user_id,
    totalCoins: Number(stats.total_coins),
    unlockedCount: Number(stats.unlocked_count),
    totalCount: Number(stats.achievements_count),
    progressPercent: Number(stats.achievements_count) === 0
      ? 0
      : Number(((Number(stats.unlocked_count) / Number(stats.achievements_count)) * 100).toFixed(2)),
    updatedAt: stats.updated_at,
  };
}

async function evaluateVerification(row, evidenceText) {
  const text = evidenceText.trim();

  if (text.length < 10) {
    return {
      approved: false,
      reason: 'Опиши доказательство подробнее, минимум 10 символов.',
    };
  }

  if (!openAiClient) {
    const words = text.split(/\s+/).filter(Boolean).length;
    const approved = text.length >= 20 && words >= 4;

    return {
      approved,
      reason: approved
        ? 'Доказательство прошло базовую текстовую проверку.'
        : 'Недостаточно деталей для подтверждения достижения.',
    };
  }

  const prompt = [
    'Ты проверяешь текстовое доказательство игрового достижения.',
    'Верни только JSON вида {"approved": true/false, "reason": "краткое объяснение на русском"}.',
    `Ключ достижения: ${row.key}`,
    `Название: ${row.title}`,
    `Описание: ${row.description}`,
    `Категория: ${row.category}`,
    `Редкость: ${row.rarity}`,
    `Требуемый прогресс: ${row.target_value}`,
    `Тип проверки: ${row.verification_type}`,
    `Текущее состояние: unlocked=${row.is_unlocked}, progress=${row.progress}`,
    `Доказательство пользователя: ${text}`,
    'Если доказательство правдоподобно и достаточно конкретно, approved=true. Иначе approved=false.',
  ].join('\n');

  const response = await openAiClient.responses.create({
    model: 'gpt-4.1-mini',
    input: prompt,
  });

  const output = (response.output_text ?? '').trim();

  try {
    const parsed = JSON.parse(output);
    const reason = typeof parsed.reason === 'string' && parsed.reason.trim().length > 0
      ? parsed.reason.trim()
      : (Boolean(parsed.approved)
          ? 'Достижение подтверждено.'
          : 'Достижение не подтверждено.');

    return {
      approved: Boolean(parsed.approved),
      reason,
    };
  } catch {
    return {
      approved: false,
      reason: output.length > 0
        ? `AI вернул неожиданный ответ: ${output}`
        : 'AI не смог подтвердить достижение.',
    };
  }
}

export async function getAchievementDefinitions() {
  const result = await getAllDefinitions();

  return {
    type: 'success',
    definitions: result.rows.map(mapDefinition),
  };
}

export async function getMyAchievements(userId) {
  const result = await withTransaction(async (client) => {
    await ensureUserAchievementRows(userId, client);
    const achievementsResult = await getUserAchievements(userId, client);
    const stats = await recalculateStats(userId, client);

    return {
      achievements: achievementsResult.rows.map(mapAchievement),
      stats,
    };
  });

  return {
    type: 'success',
    achievements: result.achievements,
    stats: result.stats,
  };
}

export async function getAchievementStats(userId) {
  const stats = await withTransaction(async (client) => {
    await ensureUserAchievementRows(userId, client);
    return recalculateStats(userId, client);
  });

  return {
    type: 'success',
    stats,
  };
}

export async function patchAchievementProgress(userId, key, payload) {
  return withTransaction(async (client) => {
    await ensureUserAchievementRows(userId, client);

    let achievementResult = await getUserAchievementByKey(userId, key, client);
    if (achievementResult.rows.length === 0) {
      return { type: 'not_found' };
    }

    let achievement = achievementResult.rows[0];

    if (!achievement.user_achievement_id) {
      await createMissingUserAchievement(userId, achievement.definition_id, client);
      achievementResult = await getUserAchievementByKey(userId, key, client);
      achievement = achievementResult.rows[0];
    }

    const absoluteProgress = payload.absoluteProgress;
    const progressDelta = payload.progressDelta ?? 0;
    const evidenceText = payload.evidenceText?.trim() || null;

    let nextProgress = absoluteProgress ?? (Number(achievement.progress) + progressDelta);
    nextProgress = Math.max(0, nextProgress);

    if (achievement.is_unlocked) {
      nextProgress = Math.max(nextProgress, Number(achievement.target_value));
    }

    const shouldUnlock = achievement.is_unlocked || nextProgress >= Number(achievement.target_value);
    const finalProgress = shouldUnlock
      ? Math.max(nextProgress, Number(achievement.target_value))
      : nextProgress;
    const unlockedAt = achievement.is_unlocked
      ? achievement.unlocked_at
      : shouldUnlock
        ? new Date()
        : null;

    await updateUserAchievementState(
      {
        userId,
        achievementDefinitionId: achievement.definition_id,
        progress: finalProgress,
        isUnlocked: shouldUnlock,
        unlockedAt,
        verificationStatus: achievement.verification_status,
        lastEvidenceText: evidenceText ?? achievement.last_evidence_text,
      },
      client,
    );

    const updatedResult = await getUserAchievementByKey(userId, key, client);
    const stats = await recalculateStats(userId, client);
    const updatedAchievement = updatedResult.rows[0];

    return {
      type: 'success',
      achievement: mapAchievement(updatedAchievement),
      stats,
      justUnlocked: !achievement.is_unlocked && updatedAchievement.is_unlocked,
    };
  });
}

export async function verifyAchievement(userId, key, evidenceText) {
  return withTransaction(async (client) => {
    await ensureUserAchievementRows(userId, client);

    let achievementResult = await getUserAchievementByKey(userId, key, client);
    if (achievementResult.rows.length === 0) {
      return { type: 'not_found' };
    }

    let achievement = achievementResult.rows[0];

    if (!achievement.user_achievement_id) {
      await createMissingUserAchievement(userId, achievement.definition_id, client);
      achievementResult = await getUserAchievementByKey(userId, key, client);
      achievement = achievementResult.rows[0];
    }

    const verification = await evaluateVerification(achievement, evidenceText);
    const approved = verification.approved;

    await updateUserAchievementState(
      {
        userId,
        achievementDefinitionId: achievement.definition_id,
        progress: approved
          ? Math.max(Number(achievement.progress), Number(achievement.target_value))
          : Number(achievement.progress),
        isUnlocked: approved ? true : achievement.is_unlocked,
        unlockedAt: approved
          ? (achievement.unlocked_at ?? new Date())
          : achievement.unlocked_at,
        verificationStatus: approved ? 'approved' : 'rejected',
        lastEvidenceText: evidenceText.trim(),
      },
      client,
    );

    const updatedResult = await getUserAchievementByKey(userId, key, client);
    const stats = await recalculateStats(userId, client);

    return {
      type: 'success',
      approved,
      reason: verification.reason,
      updatedAchievement: mapAchievement(updatedResult.rows[0]),
      stats,
    };
  });
}

export async function seedAchievementDefinitions() {
  return withTransaction(async (client) => {
    await seedDefinitions(baseAchievementDefinitions, client);
    const definitionsResult = await getAllDefinitions(client);

    return {
      type: 'success',
      definitionsCount: definitionsResult.rows.length,
      definitions: definitionsResult.rows.map(mapDefinition),
    };
  });
}

export async function getStoredUserStats(userId) {
  const result = await getUserStats(userId);

  if (result.rows.length === 0) {
    return getAchievementStats(userId);
  }

  const stats = result.rows[0];

  return {
    type: 'success',
    stats: {
      userId: stats.user_id,
      totalCoins: Number(stats.total_coins),
      unlockedCount: Number(stats.unlocked_count),
      totalCount: Number(stats.achievements_count),
      progressPercent: Number(stats.achievements_count) === 0
        ? 0
        : Number(((Number(stats.unlocked_count) / Number(stats.achievements_count)) * 100).toFixed(2)),
      updatedAt: stats.updated_at,
    },
  };
}
