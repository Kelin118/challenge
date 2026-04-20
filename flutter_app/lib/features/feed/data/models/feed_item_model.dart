import '../../domain/challenge_completion_event.dart';

class FeedItemModel {
  const FeedItemModel.challenge({required this.challenge})
      : type = 'challenge',
        completion = null;

  const FeedItemModel.completion({required this.completion})
      : type = 'completion',
        challenge = null;

  final String type;
  final Map<String, dynamic>? challenge;
  final ChallengeCompletionEvent? completion;

  factory FeedItemModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'challenge';
    if (type == 'completion') {
      return FeedItemModel.completion(
        completion: ChallengeCompletionEvent(
          id: '${json['id'] ?? ''}',
          userId: '${json['userId'] ?? ''}',
          username: json['username'] as String? ?? 'Игрок',
          challengeId: '${json['challengeId'] ?? ''}',
          challengeTitle: json['challengeTitle'] as String? ?? 'Челлендж',
          coinsEarned: _asInt(json['coinsEarned']),
          medalAwarded: json['medalAwarded'] == true,
          imageProof: json['imageProof'] as String?,
          likesCount: _asInt(json['likesCount']),
          isLikedByCurrentUser: false,
          createdAt: _asDateTime(json['createdAt']) ?? DateTime.now(),
        ),
      );
    }

    return FeedItemModel.challenge(challenge: Map<String, dynamic>.from(json));
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

DateTime? _asDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
