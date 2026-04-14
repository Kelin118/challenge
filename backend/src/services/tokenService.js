import crypto from 'crypto';
import jwt from 'jsonwebtoken';

import { requireJwtSecret } from '../config/env.js';

const ACCESS_TOKEN_EXPIRES_IN = '15m';
const REFRESH_TOKEN_TTL_DAYS = 7;

export function generateAccessToken(payload) {
  return jwt.sign(payload, requireJwtSecret(), {
    expiresIn: ACCESS_TOKEN_EXPIRES_IN,
  });
}

export function generateRefreshToken() {
  return crypto.randomBytes(64).toString('hex');
}

export function getRefreshTokenExpiresAt() {
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + REFRESH_TOKEN_TTL_DAYS);
  return expiresAt;
}

