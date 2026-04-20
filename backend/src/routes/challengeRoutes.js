import { Router } from 'express';

import {
  acceptChallengeController,
  approveSubmissionController,
  createChallengeController,
  getChallengeByIdController,
  getFeedController,
  getWalletController,
  getWalletTransactionsController,
  listChallengesController,
  rejectSubmissionController,
  submitParticipationController,
  updateParticipationProgressController,
  uploadProofController,
} from '../controllers/challengeController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { proofUploadMiddleware } from '../middleware/proofUploadMiddleware.js';
import { requireRole } from '../middleware/requireRole.js';
import { validateRequest } from '../middleware/validateRequest.js';
import {
  validateChallengeFilters,
  validateChallengeId,
  validateCreateChallenge,
} from '../validators/challenge.validator.js';
import {
  validateParticipationProgress,
  validateParticipationSubmit,
  validateSubmissionReview,
} from '../validators/challengeSubmission.validator.js';

const router = Router();

router.post('/uploads/proof', authMiddleware, proofUploadMiddleware, uploadProofController);
router.post('/challenges', authMiddleware, validateRequest(validateCreateChallenge), createChallengeController);
router.get('/challenges', validateRequest(validateChallengeFilters), listChallengesController);
router.get('/challenges/:id', validateRequest(validateChallengeId), getChallengeByIdController);
router.post('/challenges/:id/accept', authMiddleware, validateRequest(validateChallengeId), acceptChallengeController);
router.patch('/participations/:id/progress', authMiddleware, validateRequest(validateParticipationProgress), updateParticipationProgressController);
router.post('/participations/:id/submit', authMiddleware, validateRequest(validateParticipationSubmit), submitParticipationController);
router.post('/submissions/:id/approve', authMiddleware, requireRole('moderator'), validateRequest(validateSubmissionReview), approveSubmissionController);
router.post('/submissions/:id/reject', authMiddleware, requireRole('moderator'), validateRequest(validateSubmissionReview), rejectSubmissionController);
router.get('/wallet', authMiddleware, getWalletController);
router.get('/wallet/transactions', authMiddleware, getWalletTransactionsController);
router.get('/feed', getFeedController);

export default router;
