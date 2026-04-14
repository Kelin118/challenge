import { Router } from 'express';

import {
  acceptSubmissionController,
  createChallengeController,
  getChallengeByIdController,
  listChallengesController,
  rejectSubmissionController,
  submitChallengeController,
} from '../controllers/challengeController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { requireRole } from '../middleware/requireRole.js';
import { validateRequest } from '../middleware/validateRequest.js';
import {
  validateChallengeFilters,
  validateChallengeId,
  validateCreateChallenge,
} from '../validators/achievement.validator.js';
import {
  validateCreateSubmission,
  validateSubmissionId,
} from '../validators/submission.validator.js';

const router = Router();

router.post('/challenges', authMiddleware, validateRequest(validateCreateChallenge), createChallengeController);
router.get('/challenges', validateRequest(validateChallengeFilters), listChallengesController);
router.get('/challenges/:id', validateRequest(validateChallengeId), getChallengeByIdController);
router.post('/challenges/:id/submit', authMiddleware, validateRequest(validateCreateSubmission), submitChallengeController);
router.post('/submissions/:id/accept', authMiddleware, requireRole('moderator'), validateRequest(validateSubmissionId), acceptSubmissionController);
router.post('/submissions/:id/reject', authMiddleware, requireRole('moderator'), validateRequest(validateSubmissionId), rejectSubmissionController);

export default router;

