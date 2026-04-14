import { env } from '../config/env.js';
import { sendError } from '../utils/apiResponse.js';

const requestStore = new Map();

export function verifyRateLimitMiddleware(req, res, next) {
  const key = `${req.user?.id ?? 'guest'}:${req.ip ?? 'unknown'}`;
  const now = Date.now();
  const windowStart = now - env.verifyRateLimitWindowMs;
  const history = (requestStore.get(key) ?? []).filter((timestamp) => timestamp > windowStart);

  if (history.length >= env.verifyRateLimitMaxRequests) {
    return sendError(
      res,
      'Слишком много запросов на проверку. Попробуй позже.',
      429,
      'rate_limited',
    );
  }

  history.push(now);
  requestStore.set(key, history);
  return next();
}

