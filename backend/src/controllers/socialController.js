import { toggleLike, toggleSave, toggleFollow, getGroups } from '../services/socialService.js';
import { sendError, sendSuccess } from '../utils/apiResponse.js';

// POST /api/challenges/:id/like
export async function toggleLikeController(req, res) {
  const userId = req.user?.id;
  if (!userId) return sendError(res, 'Не авторизован', 401, 'unauthorized');

  const challengeId = Number(req.params.id);
  if (!Number.isInteger(challengeId) || challengeId <= 0) {
    return sendError(res, 'Некорректный id challenge', 400, 'validation_error');
  }

  try {
    const result = await toggleLike({ userId, challengeId });

    if (result.type === 'challenge_not_found') {
      return sendError(res, 'Challenge не найден', 404, 'not_found');
    }

    return sendSuccess(res, { liked: result.liked, likesCount: result.likesCount });
  } catch (error) {
    console.error('toggleLike error:', error);
    return sendError(res, 'Не удалось обновить лайк');
  }
}

// POST /api/challenges/:id/save
export async function toggleSaveController(req, res) {
  const userId = req.user?.id;
  if (!userId) return sendError(res, 'Не авторизован', 401, 'unauthorized');

  const challengeId = Number(req.params.id);
  if (!Number.isInteger(challengeId) || challengeId <= 0) {
    return sendError(res, 'Некорректный id challenge', 400, 'validation_error');
  }

  try {
    const result = await toggleSave({ userId, challengeId });

    if (result.type === 'challenge_not_found') {
      return sendError(res, 'Challenge не найден', 404, 'not_found');
    }

    return sendSuccess(res, { saved: result.saved });
  } catch (error) {
    console.error('toggleSave error:', error);
    return sendError(res, 'Не удалось обновить сохранение');
  }
}

// POST /api/users/:id/follow
export async function toggleFollowController(req, res) {
  const followerId = req.user?.id;
  if (!followerId) return sendError(res, 'Не авторизован', 401, 'unauthorized');

  const followingId = Number(req.params.id);
  if (!Number.isInteger(followingId) || followingId <= 0) {
    return sendError(res, 'Некорректный id пользователя', 400, 'validation_error');
  }

  try {
    const result = await toggleFollow({ followerId, followingId });

    if (result.type === 'self_follow') {
      return sendError(res, 'Нельзя подписаться на себя', 400, 'self_follow');
    }

    if (result.type === 'user_not_found') {
      return sendError(res, 'Пользователь не найден', 404, 'not_found');
    }

    return sendSuccess(res, { following: result.following, followersCount: result.followersCount });
  } catch (error) {
    console.error('toggleFollow error:', error);
    return sendError(res, 'Не удалось обновить подписку');
  }
}

// GET /api/groups
export async function getGroupsController(_req, res) {
  try {
    const result = await getGroups();
    return sendSuccess(res, { groups: result.groups });
  } catch (error) {
    console.error('getGroups error:', error);
    return sendError(res, 'Не удалось получить группы');
  }
}
