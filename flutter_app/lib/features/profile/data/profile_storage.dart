import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../achievements/domain/achievement.dart';
import '../domain/profile_models.dart';

class ProfileStorage {
  static const _storageKey = 'achievement-vault-flutter/progress-v2';
  static const _legacyStorageKey = 'achievement-vault-flutter/progress-v1';

  Future<AppStoragePayload?> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppStoragePayload.fromJson(decoded);
    }

    final legacyRaw = prefs.getString(_legacyStorageKey);
    if (legacyRaw == null) {
      return null;
    }

    final decoded = jsonDecode(legacyRaw);
    if (decoded is Map<String, dynamic> &&
        decoded.containsKey('progress') &&
        decoded.containsKey('customDefinitions')) {
      final progressMap = (decoded['progress'] as Map<String, dynamic>? ?? <String, dynamic>{})
          .map((key, value) => MapEntry(
                key,
                AchievementProgressState.fromJson(value as Map<String, dynamic>),
              ));

      final customItems = (decoded['customDefinitions'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => AchievementDefinition.fromJson(item as Map<String, dynamic>))
          .toList();

      return AppStoragePayload(
        activeProfileId: 'legacy-default',
        profiles: [
          UserProfileState(
            profile: LocalUserProfile(
              id: 'legacy-default',
              nickname: 'Игрок_01',
              username: 'player_01',
              about: 'Импортированный профиль',
              contact: '',
              avatarSeed: 0,
              createdAt: DateTime.now(),
            ),
            progress: progressMap,
            customDefinitions: customItems,
            verificationHistory: const [],
          ),
        ],
      );
    }

    return null;
  }

  Future<void> save(AppStoragePayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(payload.toJson()));
  }
}
