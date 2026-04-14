function invalid(message, code = 'validation_error', status = 400) {
  return { valid: false, message, code, status };
}

export function validateAchievementKey(req) {
  const key = req.params.key?.trim();

  if (!key) {
    return invalid('Ключ достижения обязателен.');
  }

  return {
    valid: true,
    data: { key },
  };
}

export function validateAchievementProgress(req) {
  const key = req.params.key?.trim();
  const absoluteProgress = req.body.absoluteProgress;
  const progressDelta = req.body.progressDelta;
  const evidenceText = req.body.evidenceText?.trim() || null;

  if (!key) {
    return invalid('Ключ достижения обязателен.');
  }

  if (absoluteProgress == null && progressDelta == null && evidenceText == null) {
    return invalid('Нужно передать absoluteProgress, progressDelta или evidenceText.');
  }

  if (absoluteProgress != null && !Number.isFinite(Number(absoluteProgress))) {
    return invalid('absoluteProgress должен быть числом.');
  }

  if (progressDelta != null && !Number.isFinite(Number(progressDelta))) {
    return invalid('progressDelta должен быть числом.');
  }

  return {
    valid: true,
    data: {
      key,
      absoluteProgress: absoluteProgress == null ? null : Number(absoluteProgress),
      progressDelta: progressDelta == null ? null : Number(progressDelta),
      evidenceText,
    },
  };
}

export function validateAchievementVerify(req) {
  const key = req.params.key?.trim();
  const evidenceText = req.body.evidenceText?.trim();

  if (!key) {
    return invalid('Ключ достижения обязателен.');
  }

  if (!evidenceText) {
    return invalid('evidenceText обязателен.');
  }

  return {
    valid: true,
    data: {
      key,
      evidenceText,
    },
  };
}

