import { query } from '../db.js';

async function run(executor, text, params = []) {
  if (executor) {
    return executor.query(text, params);
  }

  return query(text, params);
}

export async function getWalletBalance(executor, userId) {
  const result = await run(
    executor,
    `
      SELECT COALESCE(SUM(amount), 0) AS total_coins
      FROM coin_transactions
      WHERE user_id = $1
    `,
    [userId],
  );

  return Number(result.rows[0]?.total_coins ?? 0);
}

export async function createChallengeRecord(executor, {
  creatorUserId,
  title,
  description,
  category,
  type,
  rarity,
  coinCost,
  coinReward,
  creatorRewardPercent,
  proofType,
}) {
  const result = await run(
    executor,
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
        creator_reward_percent,
        proof_type
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *
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
      creatorRewardPercent,
      proofType,
    ],
  );

  return result.rows[0];
}

export async function createChallengeConditionRecord(executor, {
  challengeId,
  conditionsText,
  successCriteriaText,
  proofInstructions,
  deadlineLabel,
}) {
  const result = await run(
    executor,
    `
      INSERT INTO challenge_conditions (
        challenge_id,
        conditions_text,
        success_criteria_text,
        proof_instructions,
        deadline_label
      )
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `,
    [challengeId, conditionsText, successCriteriaText, proofInstructions, deadlineLabel],
  );

  return result.rows[0];
}

export async function createCoinTransactionRecord(executor, {
  userId,
  challengeId = null,
  submissionId = null,
  transactionType,
  amount,
  description,
}) {
  const result = await run(
    executor,
    `
      INSERT INTO coin_transactions (
        user_id,
        challenge_id,
        submission_id,
        transaction_type,
        amount,
        description
      )
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `,
    [userId, challengeId, submissionId, transactionType, amount, description],
  );

  return result.rows[0];
}

export async function listActiveChallenges(filters = {}) {
  const conditions = [`c.status = 'active'`];
  const params = [];

  if (filters.category) {
    params.push(filters.category);
    conditions.push(`c.category = $${params.length}`);
  }

  if (filters.rarity) {
    params.push(filters.rarity);
    conditions.push(`c.rarity = $${params.length}`);
  }

  if (filters.type) {
    params.push(filters.type);
    conditions.push(`c.type = $${params.length}`);
  }

  const result = await run(
    null,
    `
      SELECT
        c.*,
        u.username AS creator_username,
        cc.conditions_text,
        cc.success_criteria_text,
        cc.proof_instructions,
        cc.deadline_label,
        COALESCE(stats.participants_count, 0) AS participants_count,
        COALESCE(stats.completed_count, 0) AS completed_count
      FROM challenges c
      JOIN users u ON u.id = c.creator_user_id
      LEFT JOIN challenge_conditions cc ON cc.challenge_id = c.id
      LEFT JOIN (
        SELECT
          challenge_id,
          COUNT(*) AS participants_count,
          COUNT(*) FILTER (WHERE status = 'approved') AS completed_count
        FROM challenge_participations
        GROUP BY challenge_id
      ) stats ON stats.challenge_id = c.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY c.created_at DESC
    `,
    params,
  );

  return result.rows;
}

export async function findChallengeById(challengeId) {
  const result = await run(
    null,
    `
      SELECT
        c.*,
        u.username AS creator_username,
        cc.conditions_text,
        cc.success_criteria_text,
        cc.proof_instructions,
        cc.deadline_label,
        COALESCE(stats.participants_count, 0) AS participants_count,
        COALESCE(stats.completed_count, 0) AS completed_count
      FROM challenges c
      JOIN users u ON u.id = c.creator_user_id
      LEFT JOIN challenge_conditions cc ON cc.challenge_id = c.id
      LEFT JOIN (
        SELECT
          challenge_id,
          COUNT(*) AS participants_count,
          COUNT(*) FILTER (WHERE status = 'approved') AS completed_count
        FROM challenge_participations
        GROUP BY challenge_id
      ) stats ON stats.challenge_id = c.id
      WHERE c.id = $1
      LIMIT 1
    `,
    [challengeId],
  );

  return result.rows[0] ?? null;
}

export async function findParticipationByChallengeAndUser(executor, challengeId, userId) {
  const result = await run(
    executor,
    `
      SELECT cp.*, c.title AS challenge_title, c.coin_reward, c.creator_user_id, c.creator_reward_percent, c.proof_type
      FROM challenge_participations cp
      JOIN challenges c ON c.id = cp.challenge_id
      WHERE cp.challenge_id = $1 AND cp.user_id = $2
      LIMIT 1
    `,
    [challengeId, userId],
  );

  return result.rows[0] ?? null;
}

export async function createParticipationRecord(executor, challengeId, userId) {
  const result = await run(
    executor,
    `
      INSERT INTO challenge_participations (
        challenge_id,
        user_id,
        status,
        progress_value
      )
      VALUES ($1, $2, 'in_progress', 0)
      RETURNING *
    `,
    [challengeId, userId],
  );

  return result.rows[0];
}

export async function findParticipationById(executor, participationId) {
  const result = await run(
    executor,
    `
      SELECT
        cp.*, 
        c.title AS challenge_title,
        c.coin_reward,
        c.creator_user_id,
        c.creator_reward_percent,
        c.proof_type,
        c.rarity,
        c.category,
        c.type,
        c.status AS challenge_status
      FROM challenge_participations cp
      JOIN challenges c ON c.id = cp.challenge_id
      WHERE cp.id = $1
      LIMIT 1
    `,
    [participationId],
  );

  return result.rows[0] ?? null;
}

export async function updateParticipationProgressRecord(executor, participationId, progressValue, status = 'in_progress') {
  const result = await run(
    executor,
    `
      UPDATE challenge_participations
      SET
        progress_value = $1,
        status = $2,
        updated_at = NOW()
      WHERE id = $3
      RETURNING *
    `,
    [progressValue, status, participationId],
  );

  return result.rows[0] ?? null;
}

export async function markParticipationSubmitted(executor, participationId) {
  const result = await run(
    executor,
    `
      UPDATE challenge_participations
      SET
        status = 'submitted',
        submitted_at = NOW(),
        updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `,
    [participationId],
  );

  return result.rows[0] ?? null;
}

export async function markParticipationDecision(executor, participationId, status) {
  const approvedAt = status === 'approved';
  const rejectedAt = status === 'rejected';

  const result = await run(
    executor,
    `
      UPDATE challenge_participations
      SET
        status = $1,
        approved_at = CASE WHEN $2 THEN NOW() ELSE approved_at END,
        rejected_at = CASE WHEN $3 THEN NOW() ELSE rejected_at END,
        updated_at = NOW()
      WHERE id = $4
      RETURNING *
    `,
    [status, approvedAt, rejectedAt, participationId],
  );

  return result.rows[0] ?? null;
}

export async function createSubmissionRecord(executor, {
  challengeId,
  participationId,
  userId,
  proofUrl,
  proofType,
  comment,
}) {
  const result = await run(
    executor,
    `
      INSERT INTO challenge_submissions (
        challenge_id,
        participation_id,
        user_id,
        proof_url,
        proof_type,
        comment,
        status
      )
      VALUES ($1, $2, $3, $4, $5, $6, 'pending')
      RETURNING *
    `,
    [challengeId, participationId, userId, proofUrl, proofType, comment],
  );

  return result.rows[0];
}

export async function findSubmissionById(executor, submissionId) {
  const result = await run(
    executor,
    `
      SELECT
        cs.*,
        cp.status AS participation_status,
        cp.challenge_id AS participation_challenge_id,
        c.title AS challenge_title,
        c.coin_reward,
        c.creator_user_id,
        c.creator_reward_percent,
        c.rarity,
        u.username AS participant_username
      FROM challenge_submissions cs
      JOIN challenge_participations cp ON cp.id = cs.participation_id
      JOIN challenges c ON c.id = cs.challenge_id
      JOIN users u ON u.id = cs.user_id
      WHERE cs.id = $1
      LIMIT 1
    `,
    [submissionId],
  );

  return result.rows[0] ?? null;
}

export async function updateSubmissionReview(executor, {
  submissionId,
  status,
  reviewerUserId,
  rejectionReason = null,
  markRewardGranted = false,
}) {
  const result = await run(
    executor,
    `
      UPDATE challenge_submissions
      SET
        status = $1,
        reviewed_by_user_id = $2,
        reviewed_at = NOW(),
        rejection_reason = $3,
        reward_granted_at = CASE WHEN $4 THEN NOW() ELSE reward_granted_at END
      WHERE id = $5
      RETURNING *
    `,
    [status, reviewerUserId, rejectionReason, markRewardGranted, submissionId],
  );

  return result.rows[0] ?? null;
}

export async function createCompletionEventRecord(executor, {
  submissionId,
  challengeId,
  userId,
  coinsEarned,
  medalAwarded,
  imageProof,
}) {
  const result = await run(
    executor,
    `
      INSERT INTO completion_events (
        submission_id,
        challenge_id,
        user_id,
        coins_earned,
        medal_awarded,
        image_proof
      )
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `,
    [submissionId, challengeId, userId, coinsEarned, medalAwarded, imageProof],
  );

  return result.rows[0];
}

export async function getWalletSummary(userId) {
  const result = await run(
    null,
    `
      SELECT
        COALESCE(SUM(amount), 0) AS total_coins,
        COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) AS earned_coins,
        COALESCE(SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END), 0) AS spent_coins
      FROM coin_transactions
      WHERE user_id = $1
    `,
    [userId],
  );

  return result.rows[0];
}

export async function listWalletTransactions(userId) {
  const result = await run(
    null,
    `
      SELECT *
      FROM coin_transactions
      WHERE user_id = $1
      ORDER BY created_at DESC
      LIMIT 100
    `,
    [userId],
  );

  return result.rows;
}

export async function listCompletionEvents(limit = 30) {
  const result = await run(
    null,
    `
      SELECT
        ce.*,
        u.username,
        c.title AS challenge_title
      FROM completion_events ce
      JOIN users u ON u.id = ce.user_id
      JOIN challenges c ON c.id = ce.challenge_id
      ORDER BY ce.created_at DESC
      LIMIT $1
    `,
    [limit],
  );

  return result.rows;
}
