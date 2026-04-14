import { Router } from 'express';

import {
  getMyAchievementStats,
  listAchievementDefinitions,
  listMyAchievements,
  seedAchievementsController,
  updateAchievementProgress,
  verifyAchievementController,
} from '../controllers/achievementsController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { verifyRateLimitMiddleware } from '../middleware/rateLimit.js';
import { requireRole } from '../middleware/requireRole.js';
import { validateRequest } from '../middleware/validateRequest.js';
import {
  validateAchievementProgress,
  validateAchievementVerify,
} from '../validators/achievements.validator.js';

const router = Router();

router.get('/achievements/definitions', listAchievementDefinitions);
router.get('/achievements/my', authMiddleware, listMyAchievements);
router.get('/achievements/stats', authMiddleware, getMyAchievementStats);
router.patch(
  '/achievements/:key/progress',
  authMiddleware,
  validateRequest(validateAchievementProgress),
  updateAchievementProgress,
);
router.post(
  '/achievements/:key/verify',
  authMiddleware,
  verifyRateLimitMiddleware,
  validateRequest(validateAchievementVerify),
  verifyAchievementController,
);
router.post(
  '/achievements/seed',
  authMiddleware,
  requireRole('admin'),
  seedAchievementsController,
);

export default router;

