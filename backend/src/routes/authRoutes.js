import { Router } from 'express';

import {
  getActiveSessionsController,
  getCurrentUserController,
  loginUserController,
  logoutAllSessionsController,
  logoutSessionController,
  refreshAccessTokenController,
  registerUserController,
} from '../controllers/authController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { validateRequest } from '../middleware/validateRequest.js';
import {
  validateLogin,
  validateRefresh,
  validateRegister,
  validateSessionId,
} from '../validators/auth.validator.js';

const router = Router();

router.post('/register', validateRequest(validateRegister), registerUserController);
router.post('/login', validateRequest(validateLogin), loginUserController);
router.post('/refresh', validateRequest(validateRefresh), refreshAccessTokenController);
router.post('/logout-session', authMiddleware, validateRequest(validateSessionId), logoutSessionController);
router.post('/logout-all', authMiddleware, logoutAllSessionsController);
router.get('/me', authMiddleware, getCurrentUserController);
router.get('/sessions', authMiddleware, getActiveSessionsController);

export default router;

