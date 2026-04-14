import {
  createChallenge,
  getChallengeById,
  getChallenges,
  reviewSubmission,
  submitChallenge,
} from '../services/challengeService.js';
import { sendError, sendSuccess } from '../utils/apiResponse.js';

export async function createChallengeController(req, res) {
  const creatorUserId = req.user?.id;
  const {
    title,
    description,
    category,
    type,
    rarity,
    coinCost,
    coinReward,
    proofType,
  } = req.validated;

  if (!creatorUserId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await createChallenge({
      creatorUserId,
      title,
      description,
      category,
      type,
      rarity,
      coinCost,
      coinReward,
      proofType,
    });

    return sendSuccess(res, { challenge: result.challenge }, 201);
  } catch (error) {
    if (error?.code === '23514') {
      return sendError(res, 'Некорректные значения challenge', 400, 'validation_error');
    }

    console.error('Create challenge error:', error);
    return sendError(res, 'Не удалось создать challenge');
  }
}

export async function listChallengesController(req, res) {
  const { filters } = req.validated;

  try {
    const result = await getChallenges(filters);
    return sendSuccess(res, { challenges: result.challenges });
  } catch (error) {
    console.error('List challenges error:', error);
    return sendError(res, 'Не удалось получить challenges');
  }
}

export async function getChallengeByIdController(req, res) {
  const { challengeId } = req.validated;

  try {
    const result = await getChallengeById(challengeId);

    if (result.type === 'not_found') {
      return sendError(res, 'Challenge не найден', 404, 'not_found');
    }

    return sendSuccess(res, { challenge: result.challenge });
  } catch (error) {
    console.error('Get challenge error:', error);
    return sendError(res, 'Не удалось получить challenge');
  }
}

export async function submitChallengeController(req, res) {
  const userId = req.user?.id;
  const { challengeId, proofUrl, proofType, comment } = req.validated;

  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await submitChallenge({
      challengeId,
      userId,
      proofUrl,
      proofType,
      comment,
    });

    if (result.type === 'challenge_not_found') {
      return sendError(res, 'Challenge не найден', 404, 'not_found');
    }

    return sendSuccess(res, { submission: result.submission }, 201);
  } catch (error) {
    if (error?.code === '23514') {
      return sendError(res, 'Некорректные значения submission', 400, 'validation_error');
    }

    console.error('Submit challenge error:', error);
    return sendError(res, 'Не удалось создать submission');
  }
}

export async function acceptSubmissionController(req, res) {
  return reviewSubmissionController(req, res, 'accepted');
}

export async function rejectSubmissionController(req, res) {
  return reviewSubmissionController(req, res, 'rejected');
}

async function reviewSubmissionController(req, res, status) {
  const reviewerUserId = req.user?.id;
  const { submissionId } = req.validated;

  if (!reviewerUserId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await reviewSubmission(submissionId, reviewerUserId, status);

    if (result.type === 'not_found') {
      return sendError(res, 'Submission не найден', 404, 'not_found');
    }

    return sendSuccess(res, { submission: result.submission });
  } catch (error) {
    console.error(`${status} submission error:`, error);
    return sendError(res, 'Не удалось обновить submission');
  }
}

