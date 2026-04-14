import 'dotenv/config';

function parseCsvToSet(value) {
  return new Set(
    (value ?? '')
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean),
  );
}

function parseCsvToArray(value) {
  return (value ?? '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

export const env = {
  port: Number(process.env.PORT || 8787),
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL || '',
  jwtSecret: process.env.JWT_SECRET || '',
  openAiApiKey: process.env.OPENAI_API_KEY || '',
  corsOrigins: parseCsvToArray(process.env.CORS_ORIGINS),
  adminUsernames: parseCsvToSet(process.env.ADMIN_USERNAMES),
  adminEmails: parseCsvToSet(process.env.ADMIN_EMAILS),
  moderatorUsernames: parseCsvToSet(process.env.MODERATOR_USERNAMES),
  moderatorEmails: parseCsvToSet(process.env.MODERATOR_EMAILS),
  verifyRateLimitWindowMs: Number(process.env.VERIFY_RATE_LIMIT_WINDOW_MS || 60000),
  verifyRateLimitMaxRequests: Number(process.env.VERIFY_RATE_LIMIT_MAX_REQUESTS || 5),
};

export function requireJwtSecret() {
  if (!env.jwtSecret) {
    throw new Error('JWT_SECRET is not configured.');
  }

  return env.jwtSecret;
}

