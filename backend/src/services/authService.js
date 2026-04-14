import bcrypt from 'bcrypt';

import {
  createSession,
  createUser,
  findCurrentUserById,
  findUserByEmailOrUsername,
  findUserForLogin,
  listActiveSessionsByUserId,
  revokeAllSessionsByUserId,
  revokeSessionByIdAndUserId,
  rotateSession,
} from '../repositories/authRepository.js';
import {
  generateAccessToken,
  generateRefreshToken,
  getRefreshTokenExpiresAt,
} from './tokenService.js';

const SALT_ROUNDS = 10;

export async function registerUser({ email, username, password }) {
  const existingUser = await findUserByEmailOrUsername(email, username);

  if (existingUser.rows.length > 0) {
    const user = existingUser.rows[0];

    if (user.email === email) {
      return { type: 'conflict', field: 'email' };
    }

    if (user.username === username) {
      return { type: 'conflict', field: 'username' };
    }
  }

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
  const result = await createUser(email, username, passwordHash);

  return {
    type: 'success',
    user: result.rows[0],
  };
}

export async function loginUser({
  login,
  password,
  deviceName,
  platform,
  userAgent,
  ipAddress,
}) {
  const normalizedLogin = login.toLowerCase();
  const isEmailLogin = normalizedLogin.includes('@');
  const result = await findUserForLogin(isEmailLogin ? normalizedLogin : login, isEmailLogin);

  if (result.rows.length === 0) {
    return { type: 'not_found' };
  }

  const user = result.rows[0];
  const isPasswordValid = await bcrypt.compare(password, user.password_hash);

  if (!isPasswordValid) {
    return { type: 'invalid_password' };
  }

  const accessToken = generateAccessToken({
    id: user.id,
    email: user.email,
    username: user.username,
  });
  const refreshToken = generateRefreshToken();
  const refreshTokenExpiresAt = getRefreshTokenExpiresAt();

  await createSession({
    userId: user.id,
    refreshToken,
    deviceName,
    platform,
    userAgent,
    ipAddress,
    expiresAt: refreshTokenExpiresAt,
  });

  const { password_hash, ...safeUser } = user;

  return {
    type: 'success',
    accessToken,
    refreshToken,
    user: safeUser,
  };
}

export async function refreshSession(refreshToken) {
  const nextRefreshToken = generateRefreshToken();
  const nextRefreshTokenExpiresAt = getRefreshTokenExpiresAt();

  const result = await rotateSession(
    refreshToken,
    nextRefreshToken,
    nextRefreshTokenExpiresAt,
    generateAccessToken,
  );

  if (result.type !== 'success') {
    return result;
  }

  return {
    type: 'success',
    accessToken: result.accessToken,
    refreshToken: result.refreshToken,
  };
}

export async function getCurrentUser(userId) {
  const result = await findCurrentUserById(userId);

  if (result.rows.length === 0) {
    return { type: 'not_found' };
  }

  return {
    type: 'success',
    user: result.rows[0],
  };
}

export async function getActiveSessions(userId) {
  const result = await listActiveSessionsByUserId(userId);

  return {
    type: 'success',
    sessions: result.rows,
  };
}

export async function logoutSession(userId, sessionId) {
  const result = await revokeSessionByIdAndUserId(sessionId, userId);

  if (result.rows.length === 0) {
    return { type: 'not_found' };
  }

  return { type: 'success' };
}

export async function logoutAllSessions(userId) {
  await revokeAllSessionsByUserId(userId);

  return { type: 'success' };
}

