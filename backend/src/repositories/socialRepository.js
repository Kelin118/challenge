import { query } from '../db.js';

async function run(executor, text, params = []) {
  if (executor) return executor.query(text, params);
  return query(text, params);
}

// ---------------------------------------------------------------------------
// LIKES
// ---------------------------------------------------------------------------

export async function findLike(userId, challengeId) {
  const result = await run(null,
    `SELECT 1 FROM challenge_likes WHERE user_id = $1 AND challenge_id = $2 LIMIT 1`,
    [userId, challengeId],
  );
  return result.rows.length > 0;
}

export async function insertLike(userId, challengeId) {
  await run(null,
    `INSERT INTO challenge_likes (user_id, challenge_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
    [userId, challengeId],
  );
}

export async function deleteLike(userId, challengeId) {
  await run(null,
    `DELETE FROM challenge_likes WHERE user_id = $1 AND challenge_id = $2`,
    [userId, challengeId],
  );
}

export async function getLikesCount(challengeId) {
  const result = await run(null,
    `SELECT likes_count FROM challenges WHERE id = $1 LIMIT 1`,
    [challengeId],
  );
  return Number(result.rows[0]?.likes_count ?? 0);
}

// ---------------------------------------------------------------------------
// SAVES
// ---------------------------------------------------------------------------

export async function findSave(userId, challengeId) {
  const result = await run(null,
    `SELECT 1 FROM challenge_saves WHERE user_id = $1 AND challenge_id = $2 LIMIT 1`,
    [userId, challengeId],
  );
  return result.rows.length > 0;
}

export async function insertSave(userId, challengeId) {
  await run(null,
    `INSERT INTO challenge_saves (user_id, challenge_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
    [userId, challengeId],
  );
}

export async function deleteSave(userId, challengeId) {
  await run(null,
    `DELETE FROM challenge_saves WHERE user_id = $1 AND challenge_id = $2`,
    [userId, challengeId],
  );
}

// ---------------------------------------------------------------------------
// FOLLOWS
// ---------------------------------------------------------------------------

export async function findFollow(followerId, followingId) {
  const result = await run(null,
    `SELECT 1 FROM user_follows WHERE follower_id = $1 AND following_id = $2 LIMIT 1`,
    [followerId, followingId],
  );
  return result.rows.length > 0;
}

export async function insertFollow(followerId, followingId) {
  await run(null,
    `INSERT INTO user_follows (follower_id, following_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
    [followerId, followingId],
  );
}

export async function deleteFollow(followerId, followingId) {
  await run(null,
    `DELETE FROM user_follows WHERE follower_id = $1 AND following_id = $2`,
    [followerId, followingId],
  );
}

export async function getFollowCounts(userId) {
  const result = await run(null,
    `SELECT followers_count, following_count FROM users WHERE id = $1 LIMIT 1`,
    [userId],
  );
  return result.rows[0] ?? { followers_count: 0, following_count: 0 };
}

// ---------------------------------------------------------------------------
// GROUPS
// ---------------------------------------------------------------------------

export async function listActiveGroups() {
  const result = await run(null,
    `SELECT id, name, slug, description, icon_url, cover_url, sort_order
     FROM groups
     WHERE is_active = TRUE
     ORDER BY sort_order ASC, name ASC`,
  );
  return result.rows;
}

export async function findGroupById(groupId) {
  const result = await run(null,
    `SELECT * FROM groups WHERE id = $1 LIMIT 1`,
    [groupId],
  );
  return result.rows[0] ?? null;
}
