import { sendError } from '../utils/apiResponse.js';

export function validateRequest(validator) {
  return (req, res, next) => {
    const result = validator(req);

    if (!result.valid) {
      return sendError(res, result.message, result.status ?? 400, result.code ?? 'validation_error');
    }

    req.validated = {
      ...(req.validated ?? {}),
      ...(result.data ?? {}),
    };

    return next();
  };
}
