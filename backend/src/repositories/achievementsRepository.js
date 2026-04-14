import { query as baseQuery } from '../db.js';

function run(db, text, params = []) {
  return db.query(text, params);
}

export async function getAllDefinitions(db = { query: baseQuery }) {
  return run(
    db,
    `
      SELECT
        id,
        key,
        title,
        description,
        category,
        rarity,
        icon,
        xp_reward,
        target_value,
        is_hidden,
        verification_type,
        created_at,
        updated_at
      FROM achievement_definitions
      ORDER BY created_at ASC, id ASC
    `,
  );
}

export async function seedDefinitions(definitions, db = { query: baseQuery }) {
  for (const definition of definitions) {
    await run(
      db,
      `
        INSERT INTO achievement_definitions (
          key,
          title,
          description,
          category,
          rarity,
          icon,
          xp_reward,
          target_value,
          is_hidden,
          verification_type,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
        ON CONFLICT (key) DO UPDATE
        SET
          title = EXCLUDED.title,
          description = EXCLUDED.description,
          category = EXCLUDED.category,
          rarity = EXCLUDED.rarity,
          icon = EXCLUDED.icon,
          xp_reward = EXCLUDED.xp_reward,
          target_value = EXCLUDED.target_value,
          is_hidden = EXCLUDED.is_hidden,
          verification_type = EXCLUDED.verification_type,
          updated_at = NOW()
      `,
      [
        definition.key,
        definition.title,
        definition.description,
        definition.category,
        definition.rarity,
        definition.icon,
        definition.xpReward,
        definition.targetValue,
        definition.isHidden,
        definition.verificationType,
      ],
    );
  }
}

export async function ensureUserAchievementRows(userId, db = { query: baseQuery }) {
  return run(
    db,
    `
      INSERT INTO user_achievements (
        user_id,
        achievement_definition_id,
        progress,
        is_unlocked,
        verification_status,
        updated_at,
        created_at
      )
      SELECT
        $1,
        d.id,
        0,
        FALSE,
        'none',
        NOW(),
        NOW()
      FROM achievement_definitions d
      ON CONFLICT (user_id, achievement_definition_id) DO NOTHING
    `,
    [userId],
  );
}

export async function getUserAchievements(userId, db = { query: baseQuery }) {
  return run(
    db,
    `
      SELECT
        d.id AS definition_id,
        d.key,
        d.title,
        d.description,
        d.category,
        d.rarity,
        d.icon,
        d.xp_reward,
        d.target_value,
        d.is_hidden,
        d.verification_type,
        d.created_at AS definition_created_at,
        d.updated_at AS definition_updated_at,
        ua.id AS user_achievement_id,
        COALESCE(ua.progress, 0) AS progress,
        COALESCE(ua.is_unlocked, FALSE) AS is_unlocked,
        ua.unlocked_at,
        COALESCE(ua.verification_status, 'none') AS verification_status,
        ua.last_evidence_text,
        ua.updated_at AS user_updated_at,
        ua.created_at AS user_created_at
      FROM achievement_definitions d
      LEFT JOIN user_achievements ua
        ON ua.achievement_definition_id = d.id
       AND ua.user_id = $1
      ORDER BY d.created_at ASC, d.id ASC
    `,
    [userId],
  );
}

export async function getUserAchievementByKey(userId, key, db = { query: baseQuery }) {
  return run(
    db,
    `
      SELECT
        d.id AS definition_id,
        d.key,
        d.title,
        d.description,
        d.category,
        d.rarity,
        d.icon,
        d.xp_reward,
        d.target_value,
        d.is_hidden,
        d.verification_type,
        d.created_at AS definition_created_at,
        d.updated_at AS definition_updated_at,
        ua.id AS user_achievement_id,
        COALESCE(ua.progress, 0) AS progress,
        COALESCE(ua.is_unlocked, FALSE) AS is_unlocked,
        ua.unlocked_at,
        COALESCE(ua.verification_status, 'none') AS verification_status,
        ua.last_evidence_text,
        ua.updated_at AS user_updated_at,
        ua.created_at AS user_created_at
      FROM achievement_definitions d
      LEFT JOIN user_achievements ua
        ON ua.achievement_definition_id = d.id
       AND ua.user_id = $1
      WHERE d.key = $2
      LIMIT 1
    `,
    [userId, key],
  );
}

export async function createMissingUserAchievement(userId, achievementDefinitionId, db = { query: baseQuery }) {
  return run(
    db,
    `
      INSERT INTO user_achievements (
        user_id,
        achievement_definition_id,
        progress,
        is_unlocked,
        verification_status,
        updated_at,
        created_at
      )
      VALUES ($1, $2, 0, FALSE, 'none', NOW(), NOW())
      ON CONFLICT (user_id, achievement_definition_id) DO NOTHING
      RETURNING id
    `,
    [userId, achievementDefinitionId],
  );
}

export async function updateUserAchievementState({
  userId,
  achievementDefinitionId,
  progress,
  isUnlocked,
  unlockedAt,
  verificationStatus,
  lastEvidenceText,
}, db = { query: baseQuery }) {
  return run(
    db,
    `
      UPDATE user_achievements
      SET
        progress = $3,
        is_unlocked = $4,
        unlocked_at = $5,
        verification_status = $6,
        last_evidence_text = $7,
        updated_at = NOW()
      WHERE user_id = $1
        AND achievement_definition_id = $2
      RETURNING
        id,
        user_id,
        achievement_definition_id,
        progress,
        is_unlocked,
        unlocked_at,
        verification_status,
        last_evidence_text,
        updated_at,
        created_at
    `,
    [
      userId,
      achievementDefinitionId,
      progress,
      isUnlocked,
      unlockedAt,
      verificationStatus,
      lastEvidenceText,
    ],
  );
}

export async function getUserStats(userId, db = { query: baseQuery }) {
  return run(
    db,
    `
      SELECT
        user_id,
        total_xp,
        level,
        unlocked_count,
        achievements_count,
        updated_at
      FROM user_stats
      WHERE user_id = $1
      LIMIT 1
    `,
    [userId],
  );
}

export async function upsertUserStats({
  userId,
  totalXp,
  level,
  unlockedCount,
  achievementsCount,
}, db = { query: baseQuery }) {
  return run(
    db,
    `
      INSERT INTO user_stats (
        user_id,
        total_xp,
        level,
        unlocked_count,
        achievements_count,
        updated_at
      )
      VALUES ($1, $2, $3, $4, $5, NOW())
      ON CONFLICT (user_id) DO UPDATE
      SET
        total_xp = EXCLUDED.total_xp,
        level = EXCLUDED.level,
        unlocked_count = EXCLUDED.unlocked_count,
        achievements_count = EXCLUDED.achievements_count,
        updated_at = NOW()
      RETURNING
        user_id,
        total_xp,
        level,
        unlocked_count,
        achievements_count,
        updated_at
    `,
    [userId, totalXp, level, unlockedCount, achievementsCount],
  );
}

export async function getStatsAggregate(userId, db = { query: baseQuery }) {
  return run(
    db,
    `
      SELECT
        COALESCE(SUM(CASE WHEN ua.is_unlocked THEN d.xp_reward ELSE 0 END), 0) AS total_xp,
        COALESCE(SUM(CASE WHEN ua.is_unlocked THEN 1 ELSE 0 END), 0) AS unlocked_count,
        COUNT(d.id) AS achievements_count
      FROM achievement_definitions d
      LEFT JOIN user_achievements ua
        ON ua.achievement_definition_id = d.id
       AND ua.user_id = $1
    `,
    [userId],
  );
}

