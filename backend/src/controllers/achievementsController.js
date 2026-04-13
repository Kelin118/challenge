import {
  getAchievementDefinitions,
  getMyAchievements,
  getStoredUserStats,
  patchAchievementProgress,
  seedAchievementDefinitions,
  verifyAchievement,
} from '../services/achievementsService.js';
import { sendError, sendSuccess } from '../utils/apiResponse.js';

export async function listAchievementDefinitions(_, res) {
  try {
    const result = await getAchievementDefinitions();
    return sendSuccess(res, { definitions: result.definitions });
  } catch (error) {
    console.error('List achievement definitions error:', error);
    return sendError(res, 'Не удалось получить definitions.');
  }
}

export async function listMyAchievements(req, res) {
  const userId = req.user?.id;

  if (!userId) {
    return sendError(res, 'Не авторизован.', 401, 'unauthorized');
  }

  try {
    const result = await getMyAchievements(userId);
    return sendSuccess(res, {
      achievements: result.achievements,
      stats: result.stats,
    });
  } catch (error) {
    console.error('List my achievements error:', error);
    return sendError(res, 'Не удалось получить достижения пользователя.');
  }
}

export async function getMyAchievementStats(req, res) {
  const userId = req.user?.id;

  if (!userId) {
    return sendError(res, 'Не авторизован.', 401, 'unauthorized');
  }

  try {
    const result = await getStoredUserStats(userId);
    return sendSuccess(res, { stats: result.stats });
  } catch (error) {
    console.error('Get achievement stats error:', error);
    return sendError(res, 'Не удалось получить статистику достижений.');
  }
}

export async function updateAchievementProgress(req, res) {
  const userId = req.user?.id;

  if (!userId) {
    return sendError(res, 'Не авторизован.', 401, 'unauthorized');
  }

  try {
    const result = await patchAchievementProgress(userId, req.validated.key, req.validated);

    if (result.type === 'not_found') {
      return sendError(res, 'Достижение не найдено.', 404, 'not_found');
    }

    return sendSuccess(res, {
      achievement: result.achievement,
      stats: result.stats,
      justUnlocked: result.justUnlocked,
    });
  } catch (error) {
    console.error('Update achievement progress error:', error);
    return sendError(res, 'Не удалось обновить прогресс достижения.');
  }
}

export async function verifyAchievementController(req, res) {
  const userId = req.user?.id;

  if (!userId) {
    return sendError(res, 'Не авторизован.', 401, 'unauthorized');
  }

  try {
    const result = await verifyAchievement(userId, req.validated.key, req.validated.evidenceText);

    if (result.type === 'not_found') {
      return sendError(res, 'Достижение не найдено.', 404, 'not_found');
    }

    return sendSuccess(res, {
      approved: result.approved,
      reason: result.reason,
      updatedAchievement: result.updatedAchievement,
      stats: result.stats,
    });
  } catch (error) {
    console.error('Verify achievement error:', error);
    return sendError(res, 'Не удалось проверить достижение.');
  }
}

export async function seedAchievementsController(_, res) {
  try {
    const result = await seedAchievementDefinitions();
    return sendSuccess(res, {
      definitionsCount: result.definitionsCount,
      definitions: result.definitions,
    });
  } catch (error) {
    console.error('Seed achievement definitions error:', error);
    return sendError(res, 'Не удалось выполнить seed достижений.');
  }
}
