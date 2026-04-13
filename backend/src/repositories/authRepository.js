import { query, withTransaction } from '../db.js';

export async function findUserByEmailOrUsername(email, username) {
  return query(
    `
      SELECT email, username
      FROM users
      WHERE email = $1 OR username = $2
      LIMIT 1
    `,
    [email, username],
  );
}

export async function createUser(email, username, passwordHash) {
  return query(
    `
      INSERT INTO users (email, username, password_hash)
      VALUES ($1, $2, $3)
      RETURNING id, email, username, avatar_url, bio, status, created_at, updated_at
    `,
    [email, username, passwordHash],
  );
}

export async function findUserForLogin(login, isEmailLogin) {
  return query(
    `
      SELECT id, email, username, password_hash, avatar_url, bio, status, created_at, updated_at
      FROM users
      WHERE ${isEmailLogin ? 'email = $1' : 'username = $1'}
      LIMIT 1
    `,
    [login],
  );
}

export async function createSession({
  userId,
  refreshToken,
  deviceName,
  platform,
  userAgent,
  ipAddress,
  expiresAt,
}) {
  return query(
    `
      INSERT INTO sessions (
        user_id,
        refresh_token,
        device_name,
        platform,
        user_agent,
        ip_address,
        expires_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING
        id,
        user_id,
        refresh_token,
        device_name,
        platform,
        user_agent,
        ip_address,
        created_at,
        last_used_at,
        expires_at,
        revoked_at
    `,
    [userId, refreshToken, deviceName, platform, userAgent, ipAddress, expiresAt],
  );
}

export async function rotateSession(refreshToken, nextRefreshToken, nextExpiresAt, buildAccessToken) {
  return withTransaction(async (client) => {
    const sessionResult = await client.query(
      `
        SELECT
          s.id,
          s.user_id,
          s.device_name,
          s.platform,
          s.user_agent,
          s.ip_address,
          s.expires_at,
          s.revoked_at,
          u.email,
          u.username
        FROM sessions s
        INNER JOIN users u ON u.id = s.user_id
        WHERE s.refresh_token = $1
        LIMIT 1
      `,
      [refreshToken],
    );

    if (sessionResult.rows.length === 0) {
      return { type: 'not_found' };
    }

    const session = sessionResult.rows[0];
    const expiresAt = new Date(session.expires_at);

    if (session.revoked_at !== null) {
      return { type: 'revoked' };
    }

    if (Number.isNaN(expiresAt.getTime()) || expiresAt <= new Date()) {
      return { type: 'expired' };
    }

    await client.query(
      `
        UPDATE sessions
        SET revoked_at = NOW(),
            last_used_at = NOW()
        WHERE id = $1
      `,
      [session.id],
    );

    await client.query(
      `
        INSERT INTO sessions (
          user_id,
          refresh_token,
          device_name,
          platform,
          user_agent,
          ip_address,
          last_used_at,
          expires_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, NOW(), $7)
      `,
      [
        session.user_id,
        nextRefreshToken,
        session.device_name,
        session.platform,
        session.user_agent,
        session.ip_address,
        nextExpiresAt,
      ],
    );

    return {
      type: 'success',
      session,
      accessToken: buildAccessToken({
        id: session.user_id,
        email: session.email,
        username: session.username,
      }),
      refreshToken: nextRefreshToken,
    };
  });
}

export async function findCurrentUserById(userId) {
  return query(
    `
      SELECT id, email, username, avatar_url, bio, status, created_at, updated_at
      FROM users
      WHERE id = $1
      LIMIT 1
    `,
    [userId],
  );
}

export async function listActiveSessionsByUserId(userId) {
  return query(
    `
      SELECT
        id,
        device_name,
        platform,
        user_agent,
        ip_address,
        created_at,
        last_used_at,
        expires_at
      FROM sessions
      WHERE user_id = $1
        AND revoked_at IS NULL
        AND expires_at > NOW()
      ORDER BY last_used_at DESC, created_at DESC
    `,
    [userId],
  );
}

export async function revokeSessionByIdAndUserId(sessionId, userId) {
  return query(
    `
      UPDATE sessions
      SET revoked_at = NOW()
      WHERE id = $1
        AND user_id = $2
        AND revoked_at IS NULL
      RETURNING id
    `,
    [sessionId, userId],
  );
}

export async function revokeAllSessionsByUserId(userId) {
  return query(
    `
      UPDATE sessions
      SET revoked_at = NOW()
      WHERE user_id = $1
        AND revoked_at IS NULL
    `,
    [userId],
  );
}
