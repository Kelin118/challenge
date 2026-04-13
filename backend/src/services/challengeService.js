import {
  createChallengeRecord,
  createSubmissionRecord,
  findChallengeById,
  listActiveChallenges,
  reviewSubmissionRecord,
} from '../repositories/challengeRepository.js';

export async function createChallenge(data) {
  const result = await createChallengeRecord(data);

  return {
    type: 'success',
    challenge: result.rows[0],
  };
}

export async function getChallenges(filters) {
  const result = await listActiveChallenges(filters);

  return {
    type: 'success',
    challenges: result.rows,
  };
}

export async function getChallengeById(challengeId) {
  const result = await findChallengeById(challengeId);

  if (result.rows.length === 0) {
    return { type: 'not_found' };
  }

  return {
    type: 'success',
    challenge: result.rows[0],
  };
}

export async function submitChallenge(data) {
  const challengeResult = await findChallengeById(data.challengeId);

  if (challengeResult.rows.length === 0) {
    return { type: 'challenge_not_found' };
  }

  const result = await createSubmissionRecord(data);

  return {
    type: 'success',
    submission: result.rows[0],
  };
}

export async function reviewSubmission(submissionId, reviewerUserId, status) {
  const result = await reviewSubmissionRecord(submissionId, reviewerUserId, status);

  if (result.rows.length === 0) {
    return { type: 'not_found' };
  }

  return {
    type: 'success',
    submission: result.rows[0],
  };
}
