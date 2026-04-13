function invalid(message, code = 'validation_error', status = 400) {
  return { valid: false, message, code, status };
}

export function validateCreateChallenge(req) {
  const title = req.body.title?.trim();
  const description = req.body.description?.trim();
  const category = req.body.category?.trim();
  const type = req.body.type?.trim();
  const rarity = req.body.rarity?.trim() || 'common';
  const coinCost = Number(req.body.coin_cost ?? 0);
  const coinReward = Number(req.body.coin_reward ?? 0);
  const proofType = req.body.proof_type?.trim() || 'photo';

  if (!title || !description || !category || !type) {
    return invalid('title, description, category и type обязательны');
  }

  if (!Number.isInteger(coinCost) || !Number.isInteger(coinReward)) {
    return invalid('coin_cost и coin_reward должны быть целыми числами');
  }

  return {
    valid: true,
    data: {
      title,
      description,
      category,
      type,
      rarity,
      coinCost,
      coinReward,
      proofType,
    },
  };
}

export function validateChallengeFilters(req) {
  return {
    valid: true,
    data: {
      filters: {
        category: typeof req.query.category === 'string' && req.query.category.trim().length > 0
          ? req.query.category.trim()
          : null,
        rarity: typeof req.query.rarity === 'string' && req.query.rarity.trim().length > 0
          ? req.query.rarity.trim()
          : null,
        type: typeof req.query.type === 'string' && req.query.type.trim().length > 0
          ? req.query.type.trim()
          : null,
      },
    },
  };
}

export function validateChallengeId(req) {
  const challengeId = Number(req.params.id);

  if (!Number.isInteger(challengeId) || challengeId <= 0) {
    return invalid('Некорректный id challenge');
  }

  return {
    valid: true,
    data: { challengeId },
  };
}
