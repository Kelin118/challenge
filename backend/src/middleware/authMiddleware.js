import jwt from 'jsonwebtoken';

import { env } from '../config/env.js';
import { sendError } from '../utils/apiResponse.js';

export function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return sendError(res, 'Токен авторизации отсутствует', 401, 'unauthorized');
  }

  const token = authHeader.slice(7).trim();

  if (!token) {
    return sendError(res, 'Токен авторизации отсутствует', 401, 'unauthorized');
  }

  if (!env.jwtSecret) {
    return sendError(res, 'JWT_SECRET не настроен на backend', 500, 'server_misconfigured');
  }

  try {
    const payload = jwt.verify(token, env.jwtSecret);
    req.user = payload;
    return next();
  } catch {
    return sendError(res, 'Невалидный токен', 401, 'unauthorized');
  }
}
