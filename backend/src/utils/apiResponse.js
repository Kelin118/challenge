export function sendSuccess(res, data = {}, status = 200) {
  return res.status(status).json({
    success: true,
    data,
    error: null,
  });
}

export function sendError(res, message, status = 500, code = 'internal_error', details = null) {
  return res.status(status).json({
    success: false,
    data: null,
    error: {
      message,
      code,
      details,
    },
  });
}
