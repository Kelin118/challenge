enum AchievementRarity { common, rare, epic, legendary }

enum AchievementCategory {
  story,
  social,
  exploration,
  discipline,
  chaos,
  secret,
  custom,
}

enum VerificationStatus { none, pending, approved, rejected }

enum ProofMediaType { image, video, text, none }

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    required this.rarity,
    required this.icon,
    required this.xpReward,
    required this.targetValue,
    required this.isHidden,
    required this.verificationType,
    required this.unlockHint,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String key;
  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final String icon;
  final int xpReward;
  final int targetValue;
  final bool isHidden;
  final String verificationType;
  final String unlockHint;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'title': title,
        'description': description,
        'category': category.name,
        'rarity': rarity.name,
        'icon': icon,
        'xpReward': xpReward,
        'targetValue': targetValue,
        'isHidden': isHidden,
        'verificationType': verificationType,
        'unlockHint': unlockHint,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory AchievementDefinition.fromJson(Map<String, dynamic> json) {
    return AchievementDefinition(
      id: json['id'] as int? ?? 0,
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: _parseCategory(json['category'] as String?),
      rarity: _parseRarity(json['rarity'] as String?),
      icon: json['icon'] as String? ?? '?',
      xpReward: json['xpReward'] as int? ?? json['xp_reward'] as int? ?? 0,
      targetValue: json['targetValue'] as int? ?? json['target_value'] as int? ?? 1,
      isHidden: json['isHidden'] as bool? ?? json['is_hidden'] as bool? ?? false,
      verificationType: json['verificationType'] as String? ?? json['verification_type'] as String? ?? 'none',
      unlockHint: json['unlockHint'] as String? ?? json['unlock_hint'] as String? ?? '',
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

class AchievementProgressState {
  const AchievementProgressState({
    required this.current,
    required this.isUnlocked,
    required this.verificationStatus,
    this.unlockedAt,
    this.lastEvidenceText,
    this.createdAt,
    this.updatedAt,
  });

  final int current;
  final bool isUnlocked;
  final VerificationStatus verificationStatus;
  final DateTime? unlockedAt;
  final String? lastEvidenceText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'current': current,
        'isUnlocked': isUnlocked,
        'verificationStatus': verificationStatus.name,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'lastEvidenceText': lastEvidenceText,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory AchievementProgressState.fromJson(Map<String, dynamic> json) {
    return AchievementProgressState(
      current: json['progress'] as int? ?? json['current'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? json['is_unlocked'] as bool? ?? false,
      verificationStatus: _parseVerificationStatus(json['verificationStatus'] as String? ?? json['verification_status'] as String?),
      unlockedAt: _parseDate(json['unlockedAt'] ?? json['unlocked_at']),
      lastEvidenceText: json['lastEvidenceText'] as String? ?? json['last_evidence_text'] as String?,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

class Achievement {
  const Achievement({
    required this.definition,
    required this.progress,
  });

  final AchievementDefinition definition;
  final AchievementProgressState progress;

  String get id => definition.key;
  String get title => definition.title;
  String get description => definition.description;
  AchievementRarity get rarity => definition.rarity;
  bool get hidden => definition.isHidden;
  int get xp => definition.xpReward;
  int get maxProgress => definition.targetValue;
  String get unlockCondition => definition.unlockHint;
  String get icon => definition.icon;
  AchievementCategory get category => definition.category;
  bool get isUnlocked => progress.isUnlocked;
  String get verificationType => definition.verificationType;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final definitionJson = json['definition'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final stateJson = json['state'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    return Achievement(
      definition: AchievementDefinition.fromJson(definitionJson),
      progress: AchievementProgressState.fromJson(stateJson),
    );
  }
}

class AchievementStats {
  const AchievementStats({
    this.userId = 0,
    this.totalXp = 0,
    this.level = 1,
    this.unlockedCount = 0,
    this.totalCount = 0,
    this.progressPercent = 0,
    this.updatedAt,
  });

  final int userId;
  final int totalXp;
  final int level;
  final int unlockedCount;
  final int totalCount;
  final double progressPercent;
  final DateTime? updatedAt;

  factory AchievementStats.fromJson(Map<String, dynamic> json) {
    return AchievementStats(
      userId: json['userId'] as int? ?? json['user_id'] as int? ?? 0,
      totalXp: json['totalXp'] as int? ?? json['total_xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      unlockedCount: json['unlockedCount'] as int? ?? json['unlocked_count'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? json['achievements_count'] as int? ?? 0,
      progressPercent: (json['progressPercent'] as num? ?? 0).toDouble(),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

class AchievementSnapshot {
  const AchievementSnapshot({
    required this.achievements,
    required this.stats,
  });

  final List<Achievement> achievements;
  final AchievementStats stats;
}

class AchievementMutationResult {
  const AchievementMutationResult({
    required this.achievement,
    required this.stats,
    required this.justUnlocked,
  });

  final Achievement achievement;
  final AchievementStats stats;
  final bool justUnlocked;
}

class AchievementVerifyResult {
  const AchievementVerifyResult({
    required this.approved,
    required this.reason,
    required this.achievement,
    required this.stats,
  });

  final bool approved;
  final String reason;
  final Achievement achievement;
  final AchievementStats stats;
}

AchievementCategory _parseCategory(String? value) {
  switch (value) {
    case 'story':
      return AchievementCategory.story;
    case 'social':
      return AchievementCategory.social;
    case 'exploration':
      return AchievementCategory.exploration;
    case 'discipline':
      return AchievementCategory.discipline;
    case 'chaos':
      return AchievementCategory.chaos;
    case 'secret':
      return AchievementCategory.secret;
    default:
      return AchievementCategory.custom;
  }
}

AchievementRarity _parseRarity(String? value) {
  switch (value) {
    case 'rare':
      return AchievementRarity.rare;
    case 'epic':
      return AchievementRarity.epic;
    case 'legendary':
      return AchievementRarity.legendary;
    default:
      return AchievementRarity.common;
  }
}

VerificationStatus _parseVerificationStatus(String? value) {
  switch (value) {
    case 'pending':
      return VerificationStatus.pending;
    case 'approved':
      return VerificationStatus.approved;
    case 'rejected':
      return VerificationStatus.rejected;
    default:
      return VerificationStatus.none;
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value);
}
