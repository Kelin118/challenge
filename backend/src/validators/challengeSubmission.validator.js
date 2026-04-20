function invalid(message, code = 'validation_error', status = 400) {
  return { valid: false, message, code, status };
}

const allowedProofTypes = new Set(['photo', 'video', 'text', 'none']);

function parsePositiveId(value, entityName) {
  const id = Number(value);

  if (!Number.isInteger(id) || id <= 0) {
    return { error: invalid(`Некорректный id ${entityName}`) };
  }

  return { id };
}

export function validateParticipationId(req) {
  const parsed = parsePositiveId(req.params.id, 'participation');
  if (parsed.error) {
    return parsed.error;
  }

  return {
    valid: true,
    data: { participationId: parsed.id },
  };
}

export function validateParticipationProgress(req) {
  const parsed = parsePositiveId(req.params.id, 'participation');
  if (parsed.error) {
    return parsed.error;
  }

  const hasAbsolute = req.body.absoluteProgress !== undefined;
  const hasDelta = req.body.progressDelta !== undefined;
  const absoluteProgress = hasAbsolute ? Number(req.body.absoluteProgress) : null;
  const progressDelta = hasDelta ? Number(req.body.progressDelta) : null;

  if (!hasAbsolute && !hasDelta) {
    return invalid('Нужно передать absoluteProgress или progressDelta');
  }

  if (hasAbsolute && (!Number.isInteger(absoluteProgress) || absoluteProgress < 0 || absoluteProgress > 100)) {
    return invalid('absoluteProgress должен быть целым числом от 0 до 100');
  }

  if (hasDelta && (!Number.isInteger(progressDelta) || progressDelta < -100 || progressDelta > 100)) {
    return invalid('progressDelta должен быть целым числом от -100 до 100');
  }

  return {
    valid: true,
    data: {
      participationId: parsed.id,
      absoluteProgress,
      progressDelta,
    },
  };
}

export function validateParticipationSubmit(req) {
  const parsed = parsePositiveId(req.params.id, 'participation');
  if (parsed.error) {
    return parsed.error;
  }

  const proofUrl = req.body.proof_url?.trim() || null;
  const proofType = req.body.proof_type?.trim() || 'photo';
  const comment = req.body.comment?.trim() || null;

  if (!allowedProofTypes.has(proofType)) {
    return invalid('proof_type имеет недопустимое значение');
  }

  if (!proofUrl && !comment) {
    return invalid('Нужно передать proof_url или comment');
  }

  return {
    valid: true,
    data: {
      participationId: parsed.id,
      proofUrl,
      proofType,
      comment,
    },
  };
}

export function validateSubmissionReview(req) {
  const parsed = parsePositiveId(req.params.id, 'submission');
  if (parsed.error) {
    return parsed.error;
  }

  const reason = req.body.reason?.trim() || null;

  return {
    valid: true,
    data: {
      submissionId: parsed.id,
      reason,
    },
  };
}
