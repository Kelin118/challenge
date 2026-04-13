function invalid(message, code = 'validation_error', status = 400) {
  return { valid: false, message, code, status };
}

export function validateCreateSubmission(req) {
  const challengeId = Number(req.params.id);
  const proofUrl = req.body.proof_url?.trim() || null;
  const proofType = req.body.proof_type?.trim() || 'photo';
  const comment = req.body.comment?.trim() || null;

  if (!Number.isInteger(challengeId) || challengeId <= 0) {
    return invalid('Некорректный id challenge');
  }

  return {
    valid: true,
    data: {
      challengeId,
      proofUrl,
      proofType,
      comment,
    },
  };
}

export function validateSubmissionId(req) {
  const submissionId = Number(req.params.id);

  if (!Number.isInteger(submissionId) || submissionId <= 0) {
    return invalid('Некорректный id submission');
  }

  return {
    valid: true,
    data: { submissionId },
  };
}
