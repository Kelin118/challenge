import {
  acceptChallenge,
  approveSubmission,
  createChallenge,
  getChallengeById,
  getChallenges,
  getFeed,
  getWallet,
  getWalletTransactions,
  rejectSubmission,
  submitParticipation,
  updateParticipationProgress,
} from '../services/challengeService.js';
import { uploadProofImage } from '../services/storageService.js';
import { sendError, sendSuccess } from '../utils/apiResponse.js';

export async function createChallengeController(req, res) {
  const creatorUserId = req.user?.id;
  if (!creatorUserId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await createChallenge({ creatorUserId, ...req.validated });

    if (result.type === 'insufficient_coins') {
      return sendError(
        res,
        `Недостаточно coins для создания challenge. Нужно ${result.requiredCoins}, доступно ${result.currentCoins}.`,
        400,
        'insufficient_coins',
      );
    }

    return sendSuccess(res, { challenge: result.challenge }, 201);
  } catch (error) {
    console.error('Create challenge error:', error);
    return sendError(res, 'Не удалось создать challenge');
  }
}

export async function uploadProofController(req, res) {
  const userId = req.user?.id;
  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  if (!req.file) {
    return sendError(res, 'Файл proof не передан.', 400, 'missing_file');
  }

  try {
    const upload = await uploadProofImage({
      buffer: req.file.buffer,
      mimeType: req.file.mimetype,
      originalName: req.file.originalname,
      userId,
    });

    return sendSuccess(res, { upload }, 201);
  } catch (error) {
    console.error('Proof upload error:', error);
    return sendError(
      res,
      error instanceof Error ? error.message : 'Не удалось загрузить proof image.',
      500,
      'proof_upload_failed',
    );
  }
}

export async function listChallengesController(req, res) {
  try {
    const result = await getChallenges(req.validated.filters);
    return sendSuccess(res, { challenges: result.challenges });
  } catch (error) {
    console.error('List challenges error:', error);
    return sendError(res, 'Не удалось получить challenges');
  }
}

export async function getChallengeByIdController(req, res) {
  try {
    const result = await getChallengeById(req.validated.challengeId);

    if (result.type === 'not_found') {
      return sendError(res, 'Challenge не найден', 404, 'not_found');
    }

    return sendSuccess(res, { challenge: result.challenge });
  } catch (error) {
    console.error('Get challenge error:', error);
    return sendError(res, 'Не удалось получить challenge');
  }
}

export async function acceptChallengeController(req, res) {
  const userId = req.user?.id;
  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await acceptChallenge({ challengeId: req.validated.challengeId, userId });

    if (result.type === 'challenge_not_found') {
      return sendError(res, 'Challenge не найден', 404, 'not_found');
    }

    return sendSuccess(res, { participation: result.participation }, 201);
  } catch (error) {
    console.error('Accept challenge error:', error);
    return sendError(res, 'Не удалось принять challenge');
  }
}

export async function updateParticipationProgressController(req, res) {
  const userId = req.user?.id;
  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await updateParticipationProgress({ userId, ...req.validated });

    if (result.type === 'not_found') {
      return sendError(res, 'Participation не найден', 404, 'not_found');
    }

    if (result.type === 'forbidden') {
      return sendError(res, 'Нельзя менять чужой participation', 403, 'forbidden');
    }

    if (result.type === 'immutable_status') {
      return sendError(res, 'Participation нельзя менять в текущем статусе', 400, 'immutable_status');
    }

    return sendSuccess(res, { participation: result.participation });
  } catch (error) {
    console.error('Update participation progress error:', error);
    return sendError(res, 'Не удалось обновить progress');
  }
}

export async function submitParticipationController(req, res) {
  const userId = req.user?.id;
  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await submitParticipation({ userId, ...req.validated });

    if (result.type === 'not_found') {
      return sendError(res, 'Participation не найден', 404, 'not_found');
    }

    if (result.type === 'forbidden') {
      return sendError(res, 'Нельзя отправлять чужой submission', 403, 'forbidden');
    }

    if (result.type === 'already_approved') {
      return sendError(res, 'Participation уже подтверждён', 400, 'already_approved');
    }

    return sendSuccess(res, { participation: result.participation, submission: result.submission }, 201);
  } catch (error) {
    console.error('Submit participation error:', error);
    return sendError(res, 'Не удалось отправить submission');
  }
}

export async function approveSubmissionController(req, res) {
  const reviewerUserId = req.user?.id;
  if (!reviewerUserId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await approveSubmission({ submissionId: req.validated.submissionId, reviewerUserId });

    if (result.type === 'not_found') {
      return sendError(res, 'Submission не найден', 404, 'not_found');
    }

    if (result.type === 'already_processed') {
      return sendSuccess(res, { submission: result.submission, duplicateRewardBlocked: true });
    }

    return sendSuccess(res, {
      submission: result.submission,
      completionEvent: result.completionEvent,
    });
  } catch (error) {
    console.error('Approve submission error:', error);
    return sendError(res, 'Не удалось подтвердить submission');
  }
}

export async function rejectSubmissionController(req, res) {
  const reviewerUserId = req.user?.id;
  if (!reviewerUserId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await rejectSubmission({
      submissionId: req.validated.submissionId,
      reviewerUserId,
      reason: req.validated.reason,
    });

    if (result.type === 'not_found') {
      return sendError(res, 'Submission не найден', 404, 'not_found');
    }

    return sendSuccess(res, { submission: result.submission });
  } catch (error) {
    console.error('Reject submission error:', error);
    return sendError(res, 'Не удалось отклонить submission');
  }
}

export async function getWalletController(req, res) {
  const userId = req.user?.id;
  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await getWallet(userId);
    return sendSuccess(res, { wallet: result.wallet });
  } catch (error) {
    console.error('Get wallet error:', error);
    return sendError(res, 'Не удалось получить wallet');
  }
}

export async function getWalletTransactionsController(req, res) {
  const userId = req.user?.id;
  if (!userId) {
    return sendError(res, 'Не авторизован', 401, 'unauthorized');
  }

  try {
    const result = await getWalletTransactions(userId);
    return sendSuccess(res, { transactions: result.transactions });
  } catch (error) {
    console.error('Get wallet transactions error:', error);
    return sendError(res, 'Не удалось получить transactions');
  }
}

export async function getFeedController(_req, res) {
  try {
    const result = await getFeed();
    return sendSuccess(res, { items: result.items });
  } catch (error) {
    console.error('Get feed error:', error);
    return sendError(res, 'Не удалось получить feed');
  }
}
