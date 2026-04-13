import '../../achievements/domain/achievement.dart';

class LocalUserProfile {
  const LocalUserProfile({
    required this.id,
    required this.nickname,
    required this.username,
    required this.about,
    required this.contact,
    required this.avatarSeed,
    required this.createdAt,
  });

  final String id;
  final String nickname;
  final String username;
  final String about;
  final String contact;
  final int avatarSeed;
  final DateTime createdAt;

  String get initials => nickname.trim().isEmpty
      ? '??'
      : nickname
          .trim()
          .split(' ')
          .where((part) => part.isNotEmpty)
          .take(2)
          .map((part) => part.substring(0, 1))
          .join()
          .toUpperCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'username': username,
        'about': about,
        'contact': contact,
        'avatarSeed': avatarSeed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LocalUserProfile.fromJson(Map<String, dynamic> json) {
    return LocalUserProfile(
      id: json['id'] as String,
      nickname: json['nickname'] as String? ?? 'Игрок',
      username: json['username'] as String? ?? 'player',
      about: json['about'] as String? ?? 'Без статуса',
      contact: json['contact'] as String? ?? '',
      avatarSeed: json['avatarSeed'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class VerificationHistoryEntry {
  const VerificationHistoryEntry({
    required this.id,
    required this.achievementId,
    required this.achievementTitle,
    required this.createdAt,
    required this.status,
    required this.mediaType,
    required this.mediaPath,
    required this.message,
  });

  final String id;
  final String achievementId;
  final String achievementTitle;
  final DateTime createdAt;
  final VerificationStatus status;
  final ProofMediaType mediaType;
  final String mediaPath;
  final String message;

  Map<String, dynamic> toJson() => {
        'id': id,
        'achievementId': achievementId,
        'achievementTitle': achievementTitle,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'mediaType': mediaType.name,
        'mediaPath': mediaPath,
        'message': message,
      };

  factory VerificationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return VerificationHistoryEntry(
      id: json['id'] as String,
      achievementId: json['achievementId'] as String,
      achievementTitle: json['achievementTitle'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      status: VerificationStatus.values.byName(
        json['status'] as String? ?? VerificationStatus.pending.name,
      ),
      mediaType: ProofMediaType.values.byName(
        json['mediaType'] as String? ?? ProofMediaType.image.name,
      ),
      mediaPath: json['mediaPath'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

class UserProfileState {
  const UserProfileState({
    required this.profile,
    required this.progress,
    required this.customDefinitions,
    required this.verificationHistory,
  });

  final LocalUserProfile profile;
  final Map<String, AchievementProgressState> progress;
  final List<AchievementDefinition> customDefinitions;
  final List<VerificationHistoryEntry> verificationHistory;

  UserProfileState copyWith({
    LocalUserProfile? profile,
    Map<String, AchievementProgressState>? progress,
    List<AchievementDefinition>? customDefinitions,
    List<VerificationHistoryEntry>? verificationHistory,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      progress: progress ?? this.progress,
      customDefinitions: customDefinitions ?? this.customDefinitions,
      verificationHistory: verificationHistory ?? this.verificationHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'progress': progress.map((key, value) => MapEntry(key, value.toJson())),
        'customDefinitions': customDefinitions.map((item) => item.toJson()).toList(),
        'verificationHistory': verificationHistory.map((item) => item.toJson()).toList(),
      };

  factory UserProfileState.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return UserProfileState(
      profile: LocalUserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      progress: rawProgress.map(
        (key, value) => MapEntry(
          key,
          AchievementProgressState.fromJson(value as Map<String, dynamic>),
        ),
      ),
      customDefinitions: (json['customDefinitions'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => AchievementDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
      verificationHistory: (json['verificationHistory'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => VerificationHistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AppStoragePayload {
  const AppStoragePayload({
    required this.activeProfileId,
    required this.profiles,
  });

  final String? activeProfileId;
  final List<UserProfileState> profiles;

  Map<String, dynamic> toJson() => {
        'activeProfileId': activeProfileId,
        'profiles': profiles.map((item) => item.toJson()).toList(),
      };

  factory AppStoragePayload.fromJson(Map<String, dynamic> json) {
    return AppStoragePayload(
      activeProfileId: json['activeProfileId'] as String?,
      profiles: (json['profiles'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => UserProfileState.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlayerProfile {
  const PlayerProfile({
    required this.nickname,
    required this.totalXp,
    required this.level,
    required this.unlockedCount,
    required this.hiddenCount,
    required this.totalCount,
    required this.completionRate,
    required this.customCount,
    required this.pendingProofCount,
  });

  final String nickname;
  final int totalXp;
  final int level;
  final int unlockedCount;
  final int hiddenCount;
  final int totalCount;
  final double completionRate;
  final int customCount;
  final int pendingProofCount;
}
