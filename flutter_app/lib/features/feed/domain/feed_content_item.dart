import 'challenge_completion_event.dart';
import 'feed_challenge.dart';

enum FeedContentType { challenge, completion }

class FeedContentItem {
  const FeedContentItem.challenge(this.challenge)
      : type = FeedContentType.challenge,
        completion = null;

  const FeedContentItem.completion(this.completion)
      : type = FeedContentType.completion,
        challenge = null;

  final FeedContentType type;
  final FeedChallenge? challenge;
  final ChallengeCompletionEvent? completion;
}
