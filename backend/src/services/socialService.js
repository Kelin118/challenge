import {
  deleteLike,
  deleteSave,
  deleteFollow,
  findFollow,
  findLike,
  findSave,
  getLikesCount,
  insertFollow,
  insertLike,
  insertSave,
  listActiveGroups,
  getFollowCounts,
} from '../repositories/socialRepository.js';
import { findChallengeById } from '../repositories/challengeRepository.js';
import { findCurrentUserById } from '../repositories/authRepository.js';

// ---------------------------------------------------------------------------
// toggleLike
// ---------------------------------------------------------------------------

export async function toggleLike({ userId, challengeId }) {
  const challenge = await findChallengeById(challengeId);
  if (!challenge) return { type: 'challenge_not_found' };

  const alreadyLiked = await findLike(userId, challengeId);

  if (alreadyLiked) {
    await deleteLike(userId, challengeId);
  } else {
    await insertLike(userId, challengeId);
  }

  const likesCount = await getLikesCount(challengeId);

  return {
    type: 'ok',
    liked: !alreadyLiked,
    likesCount,
  };
}

// ---------------------------------------------------------------------------
// toggleSave
// ---------------------------------------------------------------------------

export async function toggleSave({ userId, challengeId }) {
  const challenge = await findChallengeById(challengeId);
  if (!challenge) return { type: 'challenge_not_found' };

  const alreadySaved = await findSave(userId, challengeId);

  if (alreadySaved) {
    await deleteSave(userId, challengeId);
  } else {
    await insertSave(userId, challengeId);
  }

  return {
    type: 'ok',
    saved: !alreadySaved,
  };
}

// ---------------------------------------------------------------------------
// toggleFollow
// ---------------------------------------------------------------------------

export async function toggleFollow({ followerId, followingId }) {
  if (followerId === followingId) {
    return { type: 'self_follow' };
  }

  const targetUserResult = await findCurrentUserById(followingId);
  const targetUser = targetUserResult.rows[0] ?? null;
  if (!targetUser) return { type: 'user_not_found' };

  const alreadyFollowing = await findFollow(followerId, followingId);

  if (alreadyFollowing) {
    await deleteFollow(followerId, followingId);
  } else {
    await insertFollow(followerId, followingId);
  }

  const counts = await getFollowCounts(followingId);

  return {
    type: 'ok',
    following: !alreadyFollowing,
    followersCount: Number(counts.followers_count),
  };
}

// ---------------------------------------------------------------------------
// getGroups
// ---------------------------------------------------------------------------

export async function getGroups() {
  const groups = await listActiveGroups();
  return { type: 'ok', groups };
}
