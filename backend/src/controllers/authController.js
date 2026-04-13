import {
  getActiveSessions,
  getCurrentUser,
  loginUser,
  logoutAllSessions,
  logoutSession,
  refreshSession,
  registerUser,
} from '../services/authService.js';
import { sendError, sendSuccess } from '../utils/apiResponse.js';

export async function registerUserController(req, res) {
  const { email, username, password } = req.validated;

  try {
    const result = await registerUser({ email, username, password });

    if (result.type === 'conflict') {
      return sendError(
        res,
        result.field === 'email'
          ? 'Пользователь с таким email уже существует'
          : 'Пользователь с таким username уже существует',
        409,
        'conflict',
      );
    }

    return sendSuccess(
      res,
      {
        message: 'Регистрация прошла успешно',
        user: result.user,
      },
      201,
    );
  } catch (error) {
    if (error?.code === '23505') {
      return sendError(res, 'Пользователь уже существует', 409, 'conflict');
    }

    console.error('Register error:', error);
    return sendError(res, 'Не удалось зарегистрировать пользователя');
  }
}

export async function loginUserController(req, res) {
  const { login, password, deviceName, platform } = req.validated;
  const userAgent = req.headers['user-agent'] || null;
  const forwardedFor = req.headers['x-forwarded-for'];
  const ipAddress = Array.isArray(forwardedFor)
    ? forwardedFor[0]
    : forwardedFor?.split(',')[0]?.trim() || req.ip || null;

  try {
    const result = await loginUser({
      login,
      password,
      deviceName,
      platform,
      userAgent,
      ipAddress,
    });

    if (result.type === 'not_found') {
      return sendError(res, 'Пользователь не найден', 404, 'not_found');
    }

    if (result.type === 'invalid_password') {
      return sendError(res, 'Неверный пароль', 401, 'invalid_credentials');
    }

    return sendSuccess(res, {
      message: 'Авторизация прошла успешно',
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      user: result.user,
    });
  } catch (error) {
    console.error('Login error:', error);
    return sendError(res, 'Не удалось авторизовать пользователя');
  }
}

export async function refreshAccessTokenController(req, res) {
  const { refreshToken } = req.validated;

  try {
    const result = await refreshSession(refreshToken);

    if (result.type === 'not_found' || result.type === 'revoked' || result.type === 'expired') {
      return sendError(res, 'Невалидная session', 401, 'invalid_session');
    }

    return sendSuccess(res, {
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    return sendError(res, 'Не удалось обновить токены');
  }
}

export async function getCurrentUserController(req, res) {
  const userId = req.user?.id;

  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await getCurrentUser(userId);

    if (result.type === 'not_found') {
      return sendError(res, 'Пользователь не найден', 404, 'not_found');
    }

    return sendSuccess(res, { user: result.user });
  } catch (error) {
    console.error('Get current user error:', error);
    return sendError(res, 'Не удалось получить пользователя');
  }
}

export async function getActiveSessionsController(req, res) {
  const userId = req.user?.id;

  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await getActiveSessions(userId);
    return sendSuccess(res, { sessions: result.sessions });
  } catch (error) {
    console.error('Get sessions error:', error);
    return sendError(res, 'Не удалось получить активные сессии');
  }
}

export async function logoutSessionController(req, res) {
  const userId = req.user?.id;
  const { sessionId } = req.validated;

  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await logoutSession(userId, sessionId);

    if (result.type === 'not_found') {
      return sendError(res, 'Сессия не найдена или уже отозвана', 404, 'not_found');
    }

    return sendSuccess(res, {
      message: 'Сессия завершена',
    });
  } catch (error) {
    console.error('Logout session error:', error);
    return sendError(res, 'Не удалось завершить сессию');
  }
}

export async function logoutAllSessionsController(req, res) {
  const userId = req.user?.id;

  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    await logoutAllSessions(userId);
    return sendSuccess(res, {
      message: 'Все активные сессии завершены',
    });
  } catch (error) {
    console.error('Logout all sessions error:', error);
    return sendError(res, 'Не удалось завершить все сессии');
  }
}
