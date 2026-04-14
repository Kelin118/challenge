import '../../../core/network/api_client.dart';
import '../../auth/data/auth_service.dart';
import '../domain/achievement.dart';

class AchievementApiService {
  AchievementApiService(this._authService)
      : _apiClient = _authService.apiClient;

  final AuthService _authService;
  final ApiClient _apiClient;

  Future<List<AchievementDefinition>> getAchievementDefinitions() async {
    final response = await _apiClient.getJson(
      baseUrl: _authService.baseUrl,
      path: '/api/achievements/definitions',
    );

    final definitionsJson = response['definitions'] as List<dynamic>?;
    if (definitionsJson == null) {
      return const [];
    }

    return definitionsJson
        .whereType<Map<String, dynamic>>()
        .map(AchievementDefinition.fromJson)
        .toList();
  }

  Future<AchievementSnapshot> getMyAchievements() async {
    final response = await _apiClient.getJson(
      baseUrl: _authService.baseUrl,
      path: '/api/achievements/my',
      authorized: true,
    );

    final achievementsJson = response['achievements'] as List<dynamic>? ?? const [];
    final statsJson = response['stats'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    return AchievementSnapshot(
      achievements: achievementsJson
          .whereType<Map<String, dynamic>>()
          .map(Achievement.fromJson)
          .toList(),
      stats: AchievementStats.fromJson(statsJson),
    );
  }

  Future<AchievementStats> getAchievementStats() async {
    final response = await _apiClient.getJson(
      baseUrl: _authService.baseUrl,
      path: '/api/achievements/stats',
      authorized: true,
    );

    final statsJson = response['stats'] as Map<String, dynamic>?;
    if (statsJson == null) {
      return const AchievementStats();
    }

    return AchievementStats.fromJson(statsJson);
  }

  Future<AchievementMutationResult> updateAchievementProgress({
    required String key,
    int? progressDelta,
    int? absoluteProgress,
    String? evidenceText,
  }) async {
    final response = await _apiClient.patchJson(
      baseUrl: _authService.baseUrl,
      path: '/api/achievements/$key/progress',
      body: {
        if (progressDelta != null) 'progressDelta': progressDelta,
        if (absoluteProgress != null) 'absoluteProgress': absoluteProgress,
        if (evidenceText != null && evidenceText.trim().isNotEmpty)
          'evidenceText': evidenceText.trim(),
      },
      authorized: true,
    );

    final achievementJson = response['achievement'] as Map<String, dynamic>?;
    final statsJson = response['stats'] as Map<String, dynamic>?;

    if (achievementJson == null || statsJson == null) {
      throw const AchievementApiException(
        'Сервер вернул некорректный ответ после обновления прогресса.',
      );
    }

    return AchievementMutationResult(
      achievement: Achievement.fromJson(achievementJson),
      stats: AchievementStats.fromJson(statsJson),
      justUnlocked: response['justUnlocked'] as bool? ?? false,
    );
  }

  Future<AchievementVerifyResult> verifyAchievement({
    required String key,
    required String evidenceText,
  }) async {
    final response = await _apiClient.postJson(
      baseUrl: _authService.baseUrl,
      path: '/api/achievements/$key/verify',
      body: {
        'evidenceText': evidenceText.trim(),
      },
      authorized: true,
    );

    final achievementJson = response['updatedAchievement'] as Map<String, dynamic>?;
    final statsJson = response['stats'] as Map<String, dynamic>?;

    if (achievementJson == null || statsJson == null) {
      throw const AchievementApiException(
        'Сервер вернул некорректный ответ после верификации.',
      );
    }

    return AchievementVerifyResult(
      approved: response['approved'] as bool? ?? false,
      reason: response['reason'] as String? ?? 'Ответ по проверке не был получен.',
      achievement: Achievement.fromJson(achievementJson),
      stats: AchievementStats.fromJson(statsJson),
    );
  }
}

class AchievementApiException implements Exception {
  const AchievementApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
