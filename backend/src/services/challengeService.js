import { withTransaction } from '../db.js';
import {
  createChallengeConditionRecord,
  createChallengeRecord,
  createCoinTransactionRecord,
  createCompletionEventRecord,
  createParticipationRecord,
  createSubmissionRecord,
  findChallengeById,
  findParticipationByChallengeAndUser,
  findParticipationById,
  findSubmissionById,
  getWalletBalance,
  getWalletSummary,
  listActiveChallenges,
  listCompletionEvents,
  listWalletTransactions,
  markParticipationDecision,
  markParticipationSubmitted,
  updateParticipationProgressRecord,
  updateSubmissionReview,
} from '../repositories/challengeRepository.js';

const rarityEconomy = {
  common: { coinCost: 0, creatorRewardPercent: 5 },
  rare: { coinCost: 120, creatorRewardPercent: 12 },
  epic: { coinCost: 300, creatorRewardPercent: 18 },
  legendary: { coinCost: 800, creatorRewardPercent: 25 },
  mythic: { coinCost: 1800, creatorRewardPercent: 35 },
};

export async function createChallenge(data) {
  return withTransaction(async (client) => {
    const economy = rarityEconomy[data.rarity] ?? rarityEconomy.common;
    const balance = await getWalletBalance(client, data.creatorUserId);

    if (economy.coinCost > 0 && balance < economy.coinCost) {
      return { type: 'insufficient_coins', requiredCoins: economy.coinCost, currentCoins: balance };
    }

    const challenge = await createChallengeRecord(client, {
      creatorUserId: data.creatorUserId,
      title: data.title,
      description: data.description,
      category: data.category,
      type: data.type,
      rarity: data.rarity,
      coinCost: economy.coinCost,
      coinReward: data.coinReward,
      creatorRewardPercent: economy.creatorRewardPercent,
      proofType: data.proofType,
    });

    const conditions = await createChallengeConditionRecord(client, {
      challengeId: challenge.id,
      conditionsText: data.conditionsText,
      successCriteriaText: data.successCriteriaText,
      proofInstructions: data.proofInstructions,
      deadlineLabel: data.deadlineLabel,
    });

    if (economy.coinCost > 0) {
      await createCoinTransactionRecord(client, {
        userId: data.creatorUserId,
        challengeId: challenge.id,
        transactionType: 'challenge_creation_cost',
        amount: -economy.coinCost,
        description: `Создание ${data.rarity} challenge: ${data.title}`,
      });
    }

    return {
      type: 'success',
      challenge: mapChallenge({ ...challenge, ...conditions, participants_count: 0, completed_count: 0 }),
    };
  });
}

export async function getChallenges(filters) {
  const challenges = await listActiveChallenges(filters);

  return {
    type: 'success',
    challenges: challenges.map(mapChallenge),
  };
}

export async function getChallengeById(challengeId) {
  const challenge = await findChallengeById(challengeId);

  if (!challenge) {
    return { type: 'not_found' };
  }

  return {
    type: 'success',
    challenge: mapChallenge(challenge),
  };
}

export async function acceptChallenge({ challengeId, userId }) {
  return withTransaction(async (client) => {
    const challenge = await findChallengeById(challengeId);
    if (!challenge || challenge.status !== 'active') {
      return { type: 'challenge_not_found' };
    }

    const existing = await findParticipationByChallengeAndUser(client, challengeId, userId);
    if (existing) {
      return { type: 'success', participation: mapParticipation(existing) };
    }

    const participation = await createParticipationRecord(client, challengeId, userId);
    return { type: 'success', participation: mapParticipation({ ...participation, ...challenge }) };
  });
}

export async function updateParticipationProgress({ participationId, userId, absoluteProgress, progressDelta }) {
  return withTransaction(async (client) => {
    const participation = await findParticipationById(client, participationId);
    if (!participation) {
      return { type: 'not_found' };
    }

    if (participation.user_id !== userId) {
      return { type: 'forbidden' };
    }

    if (participation.status === 'approved' || participation.status === 'submitted') {
      return { type: 'immutable_status' };
    }

    const current = Number(participation.progress_value ?? 0);
    const next = absoluteProgress !== null && absoluteProgress !== undefined
      ? absoluteProgress
      : current + (progressDelta ?? 0);

    const normalized = Math.max(0, Math.min(100, next));
    const updated = await updateParticipationProgressRecord(client, participationId, normalized, 'in_progress');

    return { type: 'success', participation: mapParticipation({ ...participation, ...updated }) };
  });
}

export async function submitParticipation({ participationId, userId, proofUrl, proofType, comment }) {
  return withTransaction(async (client) => {
    const participation = await findParticipationById(client, participationId);
    if (!participation) {
      return { type: 'not_found' };
    }

    if (participation.user_id !== userId) {
      return { type: 'forbidden' };
    }

    if (participation.status === 'approved') {
      return { type: 'already_approved' };
    }

    const updatedParticipation = await markParticipationSubmitted(client, participationId);
    const submission = await createSubmissionRecord(client, {
      challengeId: participation.challenge_id,
      participationId,
      userId,
      proofUrl,
      proofType,
      comment,
    });

    return {
      type: 'success',
      participation: mapParticipation({ ...participation, ...updatedParticipation }),
      submission: mapSubmission(submission),
    };
  });
}

export async function approveSubmission({ submissionId, reviewerUserId }) {
  return withTransaction(async (client) => {
    const submission = await findSubmissionById(client, submissionId);
    if (!submission) {
      return { type: 'not_found' };
    }

    if (submission.reward_granted_at) {
      return {
        type: 'already_processed',
        submission: mapSubmission(submission),
      };
    }

    const creatorReward = Math.floor(Number(submission.coin_reward) * Number(submission.creator_reward_percent) / 100);

    const updatedSubmission = await updateSubmissionReview(client, {
      submissionId,
      status: 'accepted',
      reviewerUserId,
      markRewardGranted: true,
    });

    await markParticipationDecision(client, submission.participation_id, 'approved');

    await createCoinTransactionRecord(client, {
      userId: submission.user_id,
      challengeId: submission.challenge_id,
      submissionId,
      transactionType: 'challenge_reward',
      amount: Number(submission.coin_reward),
      description: `Награда за выполнение challenge: ${submission.challenge_title}`,
    });

    if (creatorReward > 0 && submission.creator_user_id !== submission.user_id) {
      await createCoinTransactionRecord(client, {
        userId: submission.creator_user_id,
        challengeId: submission.challenge_id,
        submissionId,
        transactionType: 'challenge_creator_reward',
        amount: creatorReward,
        description: `Доход автора за выполнение challenge: ${submission.challenge_title}`,
      });
    }

    const completionEvent = await createCompletionEventRecord(client, {
      submissionId,
      challengeId: submission.challenge_id,
      userId: submission.user_id,
      coinsEarned: Number(submission.coin_reward),
      medalAwarded: ['rare', 'epic', 'legendary', 'mythic'].includes(submission.rarity),
      imageProof: submission.proof_url,
    });

    return {
      type: 'success',
      submission: mapSubmission(updatedSubmission),
      completionEvent: mapCompletionEvent({
        ...completionEvent,
        username: submission.participant_username,
        challenge_title: submission.challenge_title,
      }),
    };
  });
}

export async function rejectSubmission({ submissionId, reviewerUserId, reason }) {
  return withTransaction(async (client) => {
    const submission = await findSubmissionById(client, submissionId);
    if (!submission) {
      return { type: 'not_found' };
    }

    const updatedSubmission = await updateSubmissionReview(client, {
      submissionId,
      status: 'rejected',
      reviewerUserId,
      rejectionReason: reason || 'Submission отклонён модератором.',
      markRewardGranted: false,
    });

    await markParticipationDecision(client, submission.participation_id, 'rejected');

    return {
      type: 'success',
      submission: mapSubmission(updatedSubmission),
    };
  });
}

export async function getWallet(userId) {
  const wallet = await getWalletSummary(userId);

  return {
    type: 'success',
    wallet: {
      totalCoins: Number(wallet.total_coins ?? 0),
      earnedCoins: Number(wallet.earned_coins ?? 0),
      spentCoins: Number(wallet.spent_coins ?? 0),
    },
  };
}

export async function getWalletTransactions(userId) {
  const transactions = await listWalletTransactions(userId);

  return {
    type: 'success',
    transactions: transactions.map(mapTransaction),
  };
}

export async function getFeed() {
  const challenges = await listActiveChallenges({});
  const completionEvents = await listCompletionEvents(30);

  const items = [
    ...completionEvents.map((item) => ({
      type: 'completion',
      createdAt: item.created_at,
      payload: mapCompletionEvent(item),
    })),
    ...challenges.map((item) => ({
      type: 'challenge',
      createdAt: item.created_at,
      payload: mapChallenge(item),
    })),
  ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

  return {
    type: 'success',
    items: items.map((item) => ({ type: item.type, ...item.payload })),
  };
}

function mapChallenge(row) {
  return {
    id: row.id,
    creatorUserId: row.creator_user_id,
    creatorUsername: row.creator_username,
    title: row.title,
    description: row.description,
    category: row.category,
    type: row.type,
    rarity: row.rarity,
    coinCost: Number(row.coin_cost ?? 0),
    coinReward: Number(row.coin_reward ?? 0),
    creatorRewardPercent: Number(row.creator_reward_percent ?? 0),
    proofType: row.proof_type,
    status: row.status,
    conditionsText: row.conditions_text,
    successCriteriaText: row.success_criteria_text,
    proofInstructions: row.proof_instructions,
    deadlineLabel: row.deadline_label,
    participantsCount: Number(row.participants_count ?? 0),
    completedCount: Number(row.completed_count ?? 0),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function mapParticipation(row) {
  return {
    id: row.id,
    challengeId: row.challenge_id,
    userId: row.user_id,
    status: row.status,
    progressValue: Number(row.progress_value ?? 0),
    acceptedAt: row.accepted_at,
    submittedAt: row.submitted_at,
    approvedAt: row.approved_at,
    rejectedAt: row.rejected_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function mapSubmission(row) {
  return {
    id: row.id,
    challengeId: row.challenge_id,
    participationId: row.participation_id,
    userId: row.user_id,
    proofUrl: row.proof_url,
    proofType: row.proof_type,
    comment: row.comment,
    status: row.status,
    rejectionReason: row.rejection_reason,
    rewardGrantedAt: row.reward_granted_at,
    reviewedByUserId: row.reviewed_by_user_id,
    reviewedAt: row.reviewed_at,
    createdAt: row.created_at,
  };
}

function mapTransaction(row) {
  return {
    id: row.id,
    userId: row.user_id,
    challengeId: row.challenge_id,
    submissionId: row.submission_id,
    transactionType: row.transaction_type,
    amount: Number(row.amount ?? 0),
    description: row.description,
    createdAt: row.created_at,
  };
}

function mapCompletionEvent(row) {
  return {
    id: row.id,
    submissionId: row.submission_id,
    challengeId: row.challenge_id,
    userId: row.user_id,
    username: row.username,
    challengeTitle: row.challenge_title,
    coinsEarned: Number(row.coins_earned ?? 0),
    medalAwarded: Boolean(row.medal_awarded),
    imageProof: row.image_proof,
    likesCount: Number(row.likes_count ?? 0),
    createdAt: row.created_at,
  };
}
