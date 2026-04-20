function invalid(message, code = 'validation_error', status = 400) {
  return { valid: false, message, code, status };
}

const allowedTypes = new Set(['daily', 'yearly', 'permanent']);
const allowedRarities = new Set(['common', 'rare', 'epic', 'legendary', 'mythic']);
const allowedProofTypes = new Set(['photo', 'video', 'text', 'none']);

export function validateCreateChallenge(req) {
  const title = req.body.title?.trim();
  const description = req.body.description?.trim();
  const category = req.body.category?.trim();
  const type = req.body.type?.trim();
  const rarity = req.body.rarity?.trim() || 'common';
  const proofType = req.body.proof_type?.trim() || 'photo';
  const coinReward = Number(req.body.coin_reward ?? 0);
  const conditionsText = req.body.conditions_text?.trim() || req.body.conditions?.trim() || description;
  const successCriteriaText = req.body.success_criteria_text?.trim() || req.body.success_criteria?.trim() || 'Результат должен быть понятен и подтверждаем.';
  const proofInstructions = req.body.proof_instructions?.trim() || null;
  const deadlineLabel = req.body.deadline_label?.trim() || null;

  if (!title || !description || !category || !type) {
    return invalid('title, description, category и type обязательны');
  }

  if (!allowedTypes.has(type)) {
    return invalid('type должен быть daily, yearly или permanent');
  }

  if (!allowedRarities.has(rarity)) {
    return invalid('rarity имеет недопустимое значение');
  }

  if (!allowedProofTypes.has(proofType)) {
    return invalid('proof_type имеет недопустимое значение');
  }

  if (!Number.isInteger(coinReward) || coinReward < 0) {
    return invalid('coin_reward должен быть целым неотрицательным числом');
  }

  return {
    valid: true,
    data: {
      title,
      description,
      category,
      type,
      rarity,
      proofType,
      coinReward,
      conditionsText,
      successCriteriaText,
      proofInstructions,
      deadlineLabel,
    },
  };
}

export function validateChallengeFilters(req) {
  const category = typeof req.query.category === 'string' && req.query.category.trim() ? req.query.category.trim() : null;
  const rarity = typeof req.query.rarity === 'string' && req.query.rarity.trim() ? req.query.rarity.trim() : null;
  const type = typeof req.query.type === 'string' && req.query.type.trim() ? req.query.type.trim() : null;

  if (rarity && !allowedRarities.has(rarity)) {
    return invalid('rarity имеет недопустимое значение');
  }

  if (type && !allowedTypes.has(type)) {
    return invalid('type имеет недопустимое значение');
  }

  return {
    valid: true,
    data: {
      filters: { category, rarity, type },
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
