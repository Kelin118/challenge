import 'package:flutter/foundation.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/domain/profile_models.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../data/achievement_service.dart';
import '../../domain/achievement.dart';

class AchievementController extends ChangeNotifier {
  AchievementController(
    this._authController,
    this._profileController,
    this._achievementApiService,
  ) {
    _authController.addListener(_handleAuthChanged);
  }

  final AuthController _authController;
  final ProfileController _profileController;
  final AchievementApiService _achievementApiService;

  List<Achievement> _achievements = const [];
  AchievementStats _stats = const AchievementStats();
  bool _isReady = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? toastAchievementId;
  bool _lastAuthenticated = false;

  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Achievement> get achievements => _achievements;
  List<AchievementCategory> get categories =>
      _achievements.map((item) => item.category).toSet().toList();

  LocalUserProfile? get activeProfile => _profileController.activeProfile;
  UserProfileState? get activeProfileState => _profileController.activeProfileState;
  List<UserProfileState> get profiles => _profileController.profiles;
  bool get hasProfiles => _profileController.hasProfiles;
  AchievementStats get stats => _stats;

  PlayerProfile get profile {
    final nickname = activeProfile?.nickname ?? _authController.currentUser?.username ?? 'Игрок';
    final hiddenCount = _achievements.where((item) => item.hidden).length;

    return PlayerProfile(
      nickname: nickname,
      totalCoins: _stats.totalCoins,
      unlockedCount: _stats.unlockedCount,
      hiddenCount: hiddenCount,
      totalCount: _stats.totalCount,
      completionRate: _stats.progressPercent,
      customCount: 0,
      pendingProofCount: _achievements
          .where((item) => item.progress.verificationStatus == VerificationStatus.pending)
          .length,
    );
  }

  int get totalCoins => _stats.totalCoins;

  Achievement? get toastAchievement => toastAchievementId == null
      ? null
      : _achievements.where((item) => item.id == toastAchievementId).firstOrNull;

  Map<AchievementRarity, int> get unlockedByRarity => {
        for (final rarity in AchievementRarity.values)
          rarity: _achievements.where((item) => item.isUnlocked && item.rarity == rarity).length,
      };

  Map<AchievementCategory, int> get countByCategory => {
        for (final category in AchievementCategory.values)
          category: _achievements.where((item) => item.category == category).length,
      };

  Achievement? get rarestUnlocked {
    final unlocked = _achievements.where((item) => item.isUnlocked).toList();
    unlocked.sort((a, b) => a.rarity.index.compareTo(b.rarity.index));
    return unlocked.isEmpty ? null : unlocked.last;
  }

  int get unlockedCommonCount => _achievements
      .where((item) => item.isUnlocked && item.rarity == AchievementRarity.common)
      .length;

  int get unlockedRareCount => _achievements
      .where((item) => item.isUnlocked && item.rarity == AchievementRarity.rare)
      .length;

  int get unlockedEpicCount => _achievements
      .where((item) => item.isUnlocked && item.rarity == AchievementRarity.epic)
      .length;

  int get inProgressCount => _achievements
      .where((item) => !item.isUnlocked && item.progress.current > 0)
      .length;

  Future<void> load() async {
    if (!_authController.isAuthenticated) {
      _clearState(markReady: true);
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _achievementApiService.getMyAchievements();
      _achievements = snapshot.achievements;
      _stats = snapshot.stats;
      _isReady = true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _isReady = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  bool isRarityAvailable(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return true;
      case AchievementRarity.rare:
        return unlockedCommonCount >= 1;
      case AchievementRarity.epic:
        return unlockedRareCount >= 3;
      case AchievementRarity.legendary:
        return unlockedEpicCount >= 5;
    }
  }

  bool isAchievementAvailable(Achievement achievement) => isRarityAvailable(achievement.rarity);

  String rarityUnlockHint(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Обычные достижения доступны сразу.';
      case AchievementRarity.rare:
        return 'Открой 1 common-достижение, чтобы разблокировать rare.';
      case AchievementRarity.epic:
        return 'Открой 3 rare-достижения, чтобы разблокировать epic.';
      case AchievementRarity.legendary:
        return 'Открой 5 epic-достижений, чтобы разблокировать legendary.';
    }
  }

  Future<void> incrementProgress(String id, {int amount = 1}) async {
    await _updateFromServer(
      () => _achievementApiService.updateAchievementProgress(
        key: id,
        progressDelta: amount,
      ),
    );
  }

  Future<void> setProgress(String id, int value) async {
    await _updateFromServer(
      () => _achievementApiService.updateAchievementProgress(
        key: id,
        absoluteProgress: value,
      ),
    );
  }

  Future<void> unlock(String id) async {
    final achievement = _achievements.where((item) => item.id == id).firstOrNull;
    if (achievement == null) {
      return;
    }

    await _updateFromServer(
      () => _achievementApiService.updateAchievementProgress(
        key: id,
        absoluteProgress: achievement.maxProgress,
      ),
    );
  }

  Future<AchievementVerifyResult?> verify({
    required String id,
    required String evidenceText,
  }) async {
    AchievementVerifyResult? result;

    await _performMutation(() async {
      result = await _achievementApiService.verifyAchievement(
        key: id,
        evidenceText: evidenceText,
      );
      _replaceAchievement(result!.achievement);
      _stats = result!.stats;

      if (result!.approved) {
        _captureToast(result!.achievement.id);
      }
    });

    return result;
  }

  void dismissToast() {
    toastAchievementId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleAuthChanged() {
    final authenticated = _authController.isAuthenticated;

    if (authenticated && !_lastAuthenticated) {
      _lastAuthenticated = true;
      load();
      return;
    }

    if (!authenticated && _lastAuthenticated) {
      _lastAuthenticated = false;
      _clearState(markReady: true);
    }
  }

  Future<void> _updateFromServer(
    Future<AchievementMutationResult> Function() operation,
  ) async {
    await _performMutation(() async {
      final result = await operation();
      _replaceAchievement(result.achievement);
      _stats = result.stats;

      if (result.justUnlocked) {
        _captureToast(result.achievement.id);
      }
    });
  }

  Future<void> _performMutation(Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operation();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _replaceAchievement(Achievement updated) {
    _achievements = _achievements
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
  }

  void _captureToast(String achievementId) {
    toastAchievementId = achievementId;
  }

  void _clearState({required bool markReady}) {
    _achievements = const [];
    _stats = const AchievementStats();
    _errorMessage = null;
    toastAchievementId = null;
    _isLoading = false;
    _isReady = markReady;
    notifyListeners();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
