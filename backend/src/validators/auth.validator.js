function invalid(message, code = 'validation_error', status = 400) {
  return { valid: false, message, code, status };
}

export function validateRegister(req) {
  const email = req.body.email?.trim().toLowerCase();
  const username = req.body.username?.trim();
  const password = req.body.password;

  if (!email || !username || !password) {
    return invalid('email, username и password обязательны');
  }

  return {
    valid: true,
    data: { email, username, password },
  };
}

export function validateLogin(req) {
  const login = req.body.email?.trim() || req.body.username?.trim();
  const password = req.body.password;
  const deviceName = req.body.device_name?.trim() || null;
  const platform = req.body.platform?.trim() || null;

  if (!login || !password) {
    return invalid('email или username, а также password обязательны');
  }

  return {
    valid: true,
    data: { login, password, deviceName, platform },
  };
}

export function validateRefresh(req) {
  const refreshToken = req.body.refreshToken?.trim();

  if (!refreshToken) {
    return invalid('refreshToken обязателен');
  }

  return {
    valid: true,
    data: { refreshToken },
  };
}

export function validateSessionId(req) {
  const sessionId = Number(req.body.sessionId);

  if (!Number.isInteger(sessionId) || sessionId <= 0) {
    return invalid('sessionId обязателен');
  }

  return {
    valid: true,
    data: { sessionId },
  };
}
