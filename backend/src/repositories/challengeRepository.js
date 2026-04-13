import { query } from '../db.js';

export async function createChallengeRecord({
  creatorUserId,
  title,
  description,
  category,
  type,
  rarity,
  coinCost,
  coinReward,
  proofType,
}) {
  return query(
    `
      INSERT INTO challenges (
        creator_user_id,
        title,
        description,
        category,
        type,
        rarity,
        coin_cost,
        coin_reward,
        proof_type
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING
        id,
        creator_user_id,
        title,
        description,
        category,
        type,
        rarity,
        coin_cost,
        coin_reward,
        proof_type,
        status,
        created_at,
        updated_at
    `,
    [
      creatorUserId,
      title,
      description,
      category,
      type,
      rarity,
      coinCost,
      coinReward,
      proofType,
    ],
  );
}

export async function listActiveChallenges(filters) {
  const conditions = [`status = 'active'`];
  const params = [];

  if (filters.category) {
    params.push(filters.category);
    conditions.push(`category = $${params.length}`);
  }

  if (filters.rarity) {
    params.push(filters.rarity);
    conditions.push(`rarity = $${params.length}`);
  }

  if (filters.type) {
    params.push(filters.type);
    conditions.push(`type = $${params.length}`);
  }

  return query(
    `
      SELECT
        id,
        creator_user_id,
        title,
        description,
        category,
        type,
        rarity,
        coin_cost,
        coin_reward,
        proof_type,
        status,
        created_at,
        updated_at
      FROM challenges
      WHERE ${conditions.join(' AND ')}
      ORDER BY created_at DESC
    `,
    params,
  );
}

export async function findChallengeById(challengeId) {
  return query(
    `
      SELECT
        id,
        creator_user_id,
        title,
        description,
        category,
        type,
        rarity,
        coin_cost,
        coin_reward,
        proof_type,
        status,
        created_at,
        updated_at
      FROM challenges
      WHERE id = $1
      LIMIT 1
    `,
    [challengeId],
  );
}

export async function createSubmissionRecord({
  challengeId,
  userId,
  proofUrl,
  proofType,
  comment,
}) {
  return query(
    `
      INSERT INTO challenge_submissions (
        challenge_id,
        user_id,
        proof_url,
        proof_type,
        comment
      )
      VALUES ($1, $2, $3, $4, $5)
      RETURNING
        id,
        challenge_id,
        user_id,
        proof_url,
        proof_type,
        comment,
        status,
        reviewed_by_user_id,
        reviewed_at,
        created_at
    `,
    [challengeId, userId, proofUrl, proofType, comment],
  );
}

export async function reviewSubmissionRecord(submissionId, reviewerUserId, status) {
  return query(
    `
      UPDATE challenge_submissions
      SET
        status = $1,
        reviewed_by_user_id = $2,
        reviewed_at = NOW()
      WHERE id = $3
      RETURNING
        id,
        challenge_id,
        user_id,
        proof_url,
        proof_type,
        comment,
        status,
        reviewed_by_user_id,
        reviewed_at,
        created_at
    `,
    [status, reviewerUserId, submissionId],
  );
}
