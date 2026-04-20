import multer from 'multer';

import { sendError } from '../utils/apiResponse.js';

const uploader = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
  fileFilter(_req, file, callback) {
    if (!file.mimetype.startsWith('image/')) {
      callback(new Error('Нужен image proof в формате jpg, png или webp.'));
      return;
    }

    callback(null, true);
  },
}).single('proof');

export function proofUploadMiddleware(req, res, next) {
  uploader(req, res, (error) => {
    if (!error) {
      next();
      return;
    }

    if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') {
      sendError(res, 'Файл слишком большой. Максимум 10MB.', 400, 'file_too_large');
      return;
    }

    sendError(res, error.message || 'Не удалось обработать proof upload.', 400, 'upload_invalid');
  });
}
