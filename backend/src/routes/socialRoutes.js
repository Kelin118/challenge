import { Router } from 'express';

import {
  getGroupsController,
  toggleFollowController,
  toggleLikeController,
  toggleSaveController,
} from '../controllers/socialController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = Router();

// Challenges
router.post('/challenges/:id/like', authMiddleware, toggleLikeController);
router.post('/challenges/:id/save', authMiddleware, toggleSaveController);

// Users
router.post('/users/:id/follow', authMiddleware, toggleFollowController);

// Groups (публичный — Flutter читает без авторизации)
router.get('/groups', getGroupsController);

export default router;
