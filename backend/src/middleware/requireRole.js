import { env } from '../config/env.js';
import { sendError } from '../utils/apiResponse.js';

const rolePriority = {
  user: 0,
  moderator: 1,
  admin: 2,
};

function resolveRole(user) {
  if (!user) {
    return 'user';
  }

  if (env.adminUsernames.has(user.username) || env.adminEmails.has(user.email)) {
    return 'admin';
  }

  if (env.moderatorUsernames.has(user.username) || env.moderatorEmails.has(user.email)) {
    return 'moderator';
  }

  return 'user';
}

export function requireRole(requiredRole) {
  return (req, res, next) => {
    const role = resolveRole(req.user);
    req.userRole = role;

    if ((rolePriority[role] ?? 0) < (rolePriority[requiredRole] ?? 0)) {
      return sendError(res, 'Недостаточно прав для выполнения действия', 403, 'forbidden');
    }

    return next();
  };
}

