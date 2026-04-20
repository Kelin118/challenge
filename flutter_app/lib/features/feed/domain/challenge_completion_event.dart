class ChallengeCompletionEvent {
  const ChallengeCompletionEvent({
    required this.id,
    required this.userId,
    required this.username,
    required this.challengeId,
    required this.challengeTitle,
    required this.coinsEarned,
    required this.medalAwarded,
    required this.imageProof,
    required this.likesCount,
    required this.isLikedByCurrentUser,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String username;
  final String challengeId;
  final String challengeTitle;
  final int coinsEarned;
  final bool medalAwarded;
  final String? imageProof;
  final int likesCount;
  final bool isLikedByCurrentUser;
  final DateTime createdAt;

  ChallengeCompletionEvent copyWith({
    String? id,
    String? userId,
    String? username,
    String? challengeId,
    String? challengeTitle,
    int? coinsEarned,
    bool? medalAwarded,
    String? imageProof,
    bool clearImageProof = false,
    int? likesCount,
    bool? isLikedByCurrentUser,
    DateTime? createdAt,
  }) {
    return ChallengeCompletionEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      medalAwarded: medalAwarded ?? this.medalAwarded,
      imageProof: clearImageProof ? null : imageProof ?? this.imageProof,
      likesCount: likesCount ?? this.likesCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
