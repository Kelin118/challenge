import 'package:flutter/foundation.dart';

import '../../../achievements/presentation/controllers/achievement_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../data/challenge_feed_service.dart';
import '../../data/models/challenge_model.dart';
import '../../data/models/feed_item_model.dart';
import '../../data/repositories/feed_repository.dart';
import '../../domain/challenge_completion_event.dart';
import '../../domain/feed_challenge.dart';
import '../../domain/feed_content_item.dart';

class FeedController extends ChangeNotifier {
  FeedController(
    this._authController,
    this._profileController,
    this._achievementController,
    this._feedRepository,
    this._fallbackService,
  ) {
    _authController.addListener(_handleDependenciesChanged);
    _profileController.addListener(_handleDependenciesChanged);
  }

  final AuthController _authController;
  final ProfileController _profileController;
  final AchievementController _achievementController;
  final FeedRepository _feedRepository;
  final ChallengeFeedService _fallbackService;

  final Map<String, FeedChallenge> _challengeCache = {};
  final Map<String, bool> _challengeLikeOverrides = {};
  final Map<String, bool> _savedOverrides = {};
  final Map<String, bool> _followOverrides = {};
  final Map<String, bool> _completionLikeOverrides = {};
  final List<ChallengeCompletionEvent> _completionEvents = [];

  List<FeedContentItem> _items = const [];
  List<FeedChallenge> _generatedForYou = const [];
  List<String> _interests = const ['Футбол', 'CSGO', 'Кино', 'Спорт'];
  bool _isReady = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _usingFallback = false;
  FeedFilter _filter = FeedFilter.all;
  String? _selectedInterest;

  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get usingFallback => _usingFallback;
  FeedFilter get filter => _filter;
  String? get selectedInterest => _selectedInterest;
  List<String> get interests => _interests;
  List<FeedChallenge> get generatedForYou => _generatedForYou;
  int get visibleCount => visibleItems.length;

  List<FeedContentItem> get visibleItems {
    Iterable<FeedContentItem> items = _items.map(_applyOverrides);

    if (_selectedInterest != null) {
      items = items.where((item) {
        if (item.type == FeedContentType.challenge) {
          return item.challenge!.category == _selectedInterest;
        }
        return item.completion!.challengeTitle.toLowerCase().contains(_selectedInterest!.toLowerCase());
      });
    }

    switch (_filter) {
      case FeedFilter.all:
        break;
      case FeedFilter.challenges:
        items = items.where((item) => item.type == FeedContentType.challenge);
        break;
      case FeedFilter.completions:
        items = items.where((item) => item.type == FeedContentType.completion);
        break;
      case FeedFilter.subscriptions:
        items = items.where((item) => item.type == FeedContentType.challenge && item.challenge!.isFollowingAuthor);
        break;
      case FeedFilter.forYou:
        items = items.where((item) => item.type == FeedContentType.challenge && item.challenge!.recommendedFor.isNotEmpty);
        break;
    }

    return items.toList();
  }

  FeedChallenge? challengeById(String challengeId) => _challengeCache[challengeId];

  ChallengeCompletionEvent? completionByChallengeId(String challengeId) {
    return _completionEvents.where((event) => event.challengeId == challengeId).firstOrNull;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final models = await _feedRepository.fetchFeed();
      _applyFeedModels(models);
      _usingFallback = false;
      _isReady = true;
    } catch (error) {
      _applyFallbackFeed();
      _usingFallback = true;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _isReady = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(FeedFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  void setInterest(String? value) {
    if (_selectedInterest == value) return;
    _selectedInterest = value;
    notifyListeners();
  }

  void upsertChallenge(FeedChallenge challenge, {bool prepend = false}) {
    _challengeCache[challenge.id] = challenge;
    final updated = FeedContentItem.challenge(challenge);
    final existingIndex = _items.indexWhere((item) => item.type == FeedContentType.challenge && item.challenge!.id == challenge.id);
    if (existingIndex >= 0) {
      _items = [..._items]..[existingIndex] = updated;
    } else {
      _items = prepend ? [updated, ..._items] : [..._items, updated];
    }
    _refreshGeneratedForYou();
    notifyListeners();
  }

  void toggleLike(String challengeId) {
    final challenge = _challengeCache[challengeId];
    if (challenge == null) return;
    final next = !challenge.isLiked;
    _challengeLikeOverrides[challengeId] = next;
    upsertChallenge(challenge.copyWith(
      isLiked: next,
      likes: challenge.likes + (next ? 1 : -1),
    ));
  }

  void toggleSave(String challengeId) {
    final challenge = _challengeCache[challengeId];
    if (challenge == null) return;
    final next = !challenge.isSaved;
    _savedOverrides[challengeId] = next;
    upsertChallenge(challenge.copyWith(isSaved: next));
  }

  void toggleFollowAuthor(String challengeId) {
    final challenge = _challengeCache[challengeId];
    if (challenge == null) return;
    final next = !challenge.isFollowingAuthor;
    _followOverrides[challengeId] = next;
    upsertChallenge(challenge.copyWith(isFollowingAuthor: next));
  }

  void prependCompletionEvent(ChallengeCompletionEvent event) {
    _completionEvents.removeWhere((item) => item.id == event.id);
    _completionEvents.insert(0, event);
    _items = [FeedContentItem.completion(event), ..._items.where((item) => item.type != FeedContentType.completion || item.completion!.id != event.id)];
    notifyListeners();
  }

  void toggleCompletionEventLike(String completionEventId) {
    final index = _completionEvents.indexWhere((item) => item.id == completionEventId);
    if (index < 0) return;
    final current = _completionEvents[index];
    final nextLiked = !current.isLikedByCurrentUser;
    _completionLikeOverrides[completionEventId] = nextLiked;
    final updated = current.copyWith(
      isLikedByCurrentUser: nextLiked,
      likesCount: current.likesCount + (nextLiked ? 1 : -1),
    );
    _completionEvents[index] = updated;
    final itemIndex = _items.indexWhere((item) => item.type == FeedContentType.completion && item.completion!.id == completionEventId);
    if (itemIndex >= 0) {
      _items = [..._items]..[itemIndex] = FeedContentItem.completion(updated);
    }
    notifyListeners();
  }

  String buildCompletionShareText(ChallengeCompletionEvent event) {
    return '${event.username} выполнил челлендж "${event.challengeTitle}" и заработал ${event.coinsEarned} coins.';
  }

  void _applyFeedModels(List<FeedItemModel> models) {
    _completionEvents.clear();
    _items = models.map((item) {
      if (item.type == 'completion') {
        final event = item.completion!;
        _completionEvents.add(event);
        return FeedContentItem.completion(event);
      }

      final model = ChallengeModel.fromJson(item.challenge!);
      final challenge = model.toFeedChallenge(
        isLiked: _challengeLikeOverrides['${model.id}'] ?? false,
        isSaved: _savedOverrides['${model.id}'] ?? false,
        isFollowingAuthor: _followOverrides['${model.id}'] ?? false,
      );
      _challengeCache[challenge.id] = challenge;
      return FeedContentItem.challenge(challenge);
    }).toList();

    _interests = _deriveInterests();
    _refreshGeneratedForYou();
  }

  void _applyFallbackFeed() {
    final fallback = _fallbackService.buildFeed(
      profile: _profileController.activeProfile,
      achievements: _achievementController.achievements,
    );
    _challengeCache
      ..clear()
      ..addEntries(fallback.challenges.map((item) => MapEntry(item.id, item)));
    _completionEvents.clear();
    _items = fallback.challenges.map(FeedContentItem.challenge).toList();
    _generatedForYou = fallback.generatedForYou;
    _interests = fallback.interests;
  }

  List<String> _deriveInterests() {
    final fromFeed = _items
        .where((item) => item.type == FeedContentType.challenge)
        .map((item) => item.challenge!.category)
        .toSet()
        .toList();

    if (fromFeed.isNotEmpty) {
      return fromFeed.take(8).toList();
    }

    final about = (_profileController.activeProfile?.about ?? '').toLowerCase();
    final derived = <String>[];
    if (about.contains('фут')) derived.add('Футбол');
    if (about.contains('csg') || about.contains('counter')) derived.add('CSGO');
    if (about.contains('кино')) derived.add('Кино');
    if (about.contains('спорт')) derived.add('Спорт');
    return derived.isEmpty ? const ['Футбол', 'CSGO', 'Кино', 'Спорт'] : derived;
  }

  void _refreshGeneratedForYou() {
    final preferred = interests.toSet();
    _generatedForYou = _challengeCache.values.where((item) => preferred.contains(item.category)).take(5).toList();
  }

  FeedContentItem _applyOverrides(FeedContentItem item) {
    if (item.type == FeedContentType.challenge) {
      final challenge = _challengeCache[item.challenge!.id] ?? item.challenge!;
      return FeedContentItem.challenge(challenge);
    }

    final completion = _completionEvents.where((event) => event.id == item.completion!.id).firstOrNull ?? item.completion!;
    return FeedContentItem.completion(completion);
  }

  void _handleDependenciesChanged() {
    if (_isReady && !_isLoading) {
      load();
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_handleDependenciesChanged);
    _profileController.removeListener(_handleDependenciesChanged);
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}


