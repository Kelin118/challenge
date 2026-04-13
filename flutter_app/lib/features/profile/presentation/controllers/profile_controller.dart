import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;

import '../../data/profile_storage.dart';
import '../../domain/profile_models.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._storage);

  final ProfileStorage _storage;

  bool _isReady = false;
  List<UserProfileState> _profiles = const [];
  String? _activeProfileId;

  bool get isReady => _isReady;
  List<UserProfileState> get profiles => _profiles;
  bool get hasProfiles => _profiles.isNotEmpty;

  UserProfileState? get activeProfileState =>
      _profiles.where((item) => item.profile.id == _activeProfileId).firstOrNull;

  LocalUserProfile? get activeProfile => activeProfileState?.profile;

  Future<void> load() async {
    final payload = await _storage.load();
    _profiles = payload?.profiles ?? const [];
    _activeProfileId = payload?.activeProfileId ?? _profiles.firstOrNull?.profile.id;
    _isReady = true;
    notifyListeners();
  }

  Future<void> registerProfile({
    required String nickname,
    required String username,
    required String about,
    required String contact,
  }) async {
    final trimmedNickname = nickname.trim();
    final normalizedUsername = username.trim().replaceAll(' ', '').toLowerCase();

    if (trimmedNickname.isEmpty || normalizedUsername.isEmpty) {
      return;
    }

    final id = 'profile-${DateTime.now().millisecondsSinceEpoch}';

    final profileState = UserProfileState(
      profile: LocalUserProfile(
        id: id,
        nickname: trimmedNickname,
        username: normalizedUsername.startsWith('@')
            ? normalizedUsername
            : '@$normalizedUsername',
        about: about.trim().isEmpty ? '����� � ������ ������.' : about.trim(),
        contact: contact.trim(),
        avatarSeed: DateTime.now().millisecondsSinceEpoch % Colors.primaries.length,
        createdAt: DateTime.now(),
      ),
      progress: const {},
      customDefinitions: const [],
      verificationHistory: const [],
    );

    _profiles = [..._profiles, profileState];
    _activeProfileId = id;
    await _persist();
    notifyListeners();
  }

  Future<void> switchProfile(String profileId) async {
    if (_activeProfileId == profileId) {
      return;
    }

    _activeProfileId = profileId;
    await _persist();
    notifyListeners();
  }

  Future<void> updateActiveProfile({
    required String nickname,
    required String username,
    required String about,
    required String contact,
  }) async {
    final active = activeProfileState;
    if (active == null) {
      return;
    }

    final trimmedNickname = nickname.trim();
    final trimmedUsername = username.trim();

    if (trimmedNickname.isEmpty || trimmedUsername.isEmpty) {
      return;
    }

    _profiles = _profiles
        .map((item) => item.profile.id == active.profile.id
            ? item.copyWith(
                profile: LocalUserProfile(
                  id: item.profile.id,
                  nickname: trimmedNickname,
                  username: trimmedUsername.startsWith('@')
                      ? trimmedUsername
                      : '@$trimmedUsername',
                  about: about.trim().isEmpty ? item.profile.about : about.trim(),
                  contact: contact.trim(),
                  avatarSeed: item.profile.avatarSeed,
                  createdAt: item.profile.createdAt,
                ),
              )
            : item)
        .toList();

    await _persist();
    notifyListeners();
  }

  Future<void> deleteProfile(String profileId) async {
    _profiles = _profiles.where((item) => item.profile.id != profileId).toList();

    if (_profiles.isEmpty) {
      _activeProfileId = null;
    } else if (_activeProfileId == profileId) {
      _activeProfileId = _profiles.first.profile.id;
    }

    await _persist();
    notifyListeners();
  }

  Future<void> _persist() {
    return _storage.save(
      AppStoragePayload(
        activeProfileId: _activeProfileId,
        profiles: _profiles,
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
