import '../../achievements/domain/achievement.dart';

enum FeedFilter { all, challenges, completions, subscriptions, forYou }

enum FeedChallengeType { daily, yearly, permanent }

enum FeedChallengeRarity { common, rare, epic, legendary, mythic }

enum FeedChallengeSource { user, system, recommended }

enum FeedVerificationType { photo, text, community, moderator, system }

enum FeedExecutionStatus { notAccepted, inProgress, submitted, approved, rejected }

class FeedChallenge {
  const FeedChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.fullDescription,
    required this.category,
    required this.type,
    required this.rarity,
    required this.coinReward,
    required this.authorName,
    required this.authorHandle,
    required this.source,
    required this.sourceTag,
    required this.likes,
    required this.isAccepted,
    required this.isLiked,
    required this.isSaved,
    required this.isFollowingAuthor,
    required this.isSystemGenerated,
    required this.recommendedFor,
    required this.reason,
    required this.progress,
    required this.participants,
    required this.acceptedCount,
    required this.completedCount,
    required this.rules,
    required this.successCriteria,
    required this.limitations,
    required this.deadlineLabel,
    required this.hasMedal,
    required this.medalTitle,
    required this.specialStatus,
    required this.creatorChallengeCount,
    required this.creatorCommissionPercent,
    required this.verificationType,
    required this.executionStatus,
    required this.submissionText,
    required this.submissionImagePath,
    required this.rejectionReason,
    required this.medalAwarded,
    required this.completionLikes,
  });

  final String id;
  final String title;
  final String description;
  final String fullDescription;
  final String category;
  final FeedChallengeType type;
  final FeedChallengeRarity rarity;
  final int coinReward;
  final String authorName;
  final String authorHandle;
  final FeedChallengeSource source;
  final String sourceTag;
  final int likes;
  final bool isAccepted;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowingAuthor;
  final bool isSystemGenerated;
  final List<String> recommendedFor;
  final String reason;
  final double progress;
  final int participants;
  final int acceptedCount;
  final int completedCount;
  final List<String> rules;
  final List<String> successCriteria;
  final String limitations;
  final String deadlineLabel;
  final bool hasMedal;
  final String medalTitle;
  final String specialStatus;
  final int creatorChallengeCount;
  final int creatorCommissionPercent;
  final FeedVerificationType verificationType;
  final FeedExecutionStatus executionStatus;
  final String submissionText;
  final String? submissionImagePath;
  final String? rejectionReason;
  final bool medalAwarded;
  final int completionLikes;

  FeedChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? fullDescription,
    String? category,
    FeedChallengeType? type,
    FeedChallengeRarity? rarity,
    int? coinReward,
    String? authorName,
    String? authorHandle,
    FeedChallengeSource? source,
    String? sourceTag,
    int? likes,
    bool? isAccepted,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowingAuthor,
    bool? isSystemGenerated,
    List<String>? recommendedFor,
    String? reason,
    double? progress,
    int? participants,
    int? acceptedCount,
    int? completedCount,
    List<String>? rules,
    List<String>? successCriteria,
    String? limitations,
    String? deadlineLabel,
    bool? hasMedal,
    String? medalTitle,
    String? specialStatus,
    int? creatorChallengeCount,
    int? creatorCommissionPercent,
    FeedVerificationType? verificationType,
    FeedExecutionStatus? executionStatus,
    String? submissionText,
    String? submissionImagePath,
    bool clearSubmissionImagePath = false,
    String? rejectionReason,
    bool clearRejectionReason = false,
    bool? medalAwarded,
    int? completionLikes,
  }) {
    return FeedChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      fullDescription: fullDescription ?? this.fullDescription,
      category: category ?? this.category,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      coinReward: coinReward ?? this.coinReward,
      authorName: authorName ?? this.authorName,
      authorHandle: authorHandle ?? this.authorHandle,
      source: source ?? this.source,
      sourceTag: sourceTag ?? this.sourceTag,
      likes: likes ?? this.likes,
      isAccepted: isAccepted ?? this.isAccepted,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
      isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
      recommendedFor: recommendedFor ?? this.recommendedFor,
      reason: reason ?? this.reason,
      progress: progress ?? this.progress,
      participants: participants ?? this.participants,
      acceptedCount: acceptedCount ?? this.acceptedCount,
      completedCount: completedCount ?? this.completedCount,
      rules: rules ?? this.rules,
      successCriteria: successCriteria ?? this.successCriteria,
      limitations: limitations ?? this.limitations,
      deadlineLabel: deadlineLabel ?? this.deadlineLabel,
      hasMedal: hasMedal ?? this.hasMedal,
      medalTitle: medalTitle ?? this.medalTitle,
      specialStatus: specialStatus ?? this.specialStatus,
      creatorChallengeCount: creatorChallengeCount ?? this.creatorChallengeCount,
      creatorCommissionPercent: creatorCommissionPercent ?? this.creatorCommissionPercent,
      verificationType: verificationType ?? this.verificationType,
      executionStatus: executionStatus ?? this.executionStatus,
      submissionText: submissionText ?? this.submissionText,
      submissionImagePath: clearSubmissionImagePath ? null : submissionImagePath ?? this.submissionImagePath,
      rejectionReason: clearRejectionReason ? null : rejectionReason ?? this.rejectionReason,
      medalAwarded: medalAwarded ?? this.medalAwarded,
      completionLikes: completionLikes ?? this.completionLikes,
    );
  }
}

class ChallengeDraft {
  const ChallengeDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.rarity,
    required this.coinReward,
    required this.conditions,
    required this.verificationType,
    required this.creationCost,
    required this.revenueShare,
  });

  final String title;
  final String description;
  final String category;
  final FeedChallengeType type;
  final FeedChallengeRarity rarity;
  final int coinReward;
  final String conditions;
  final FeedVerificationType verificationType;
  final int creationCost;
  final int revenueShare;
}

class FeedSnapshot {
  const FeedSnapshot({
    required this.challenges,
    required this.generatedForYou,
    required this.interests,
  });

  final List<FeedChallenge> challenges;
  final List<FeedChallenge> generatedForYou;
  final List<String> interests;
}

String feedFilterLabel(FeedFilter filter) {
  switch (filter) {
    case FeedFilter.all:
      return 'Все';
    case FeedFilter.challenges:
      return 'Челленджи';
    case FeedFilter.completions:
      return 'Выполнения';
    case FeedFilter.subscriptions:
      return 'Подписки';
    case FeedFilter.forYou:
      return 'Для тебя';
  }
}

String feedChallengeTypeLabel(FeedChallengeType type) {
  switch (type) {
    case FeedChallengeType.daily:
      return 'Дневной';
    case FeedChallengeType.yearly:
      return 'Годовой';
    case FeedChallengeType.permanent:
      return 'Постоянный';
  }
}

String feedChallengeRarityLabel(FeedChallengeRarity rarity) {
  switch (rarity) {
    case FeedChallengeRarity.common:
      return 'Обычный';
    case FeedChallengeRarity.rare:
      return 'Редкий';
    case FeedChallengeRarity.epic:
      return 'Эпический';
    case FeedChallengeRarity.legendary:
      return 'Легендарный';
    case FeedChallengeRarity.mythic:
      return 'Мифический';
  }
}

String feedVerificationTypeLabel(FeedVerificationType type) {
  switch (type) {
    case FeedVerificationType.photo:
      return 'Фото / видео';
    case FeedVerificationType.text:
      return 'Текстовое описание';
    case FeedVerificationType.community:
      return 'Проверка сообществом';
    case FeedVerificationType.moderator:
      return 'Проверка модератором';
    case FeedVerificationType.system:
      return 'Системная проверка';
  }
}

String feedExecutionStatusLabel(FeedExecutionStatus status) {
  switch (status) {
    case FeedExecutionStatus.notAccepted:
      return 'Не принят';
    case FeedExecutionStatus.inProgress:
      return 'В процессе';
    case FeedExecutionStatus.submitted:
      return 'Отправлен';
    case FeedExecutionStatus.approved:
      return 'Подтверждён';
    case FeedExecutionStatus.rejected:
      return 'Отклонён';
  }
}

FeedChallengeRarity mapAchievementRarity(AchievementRarity rarity) {
  switch (rarity) {
    case AchievementRarity.common:
      return FeedChallengeRarity.common;
    case AchievementRarity.rare:
      return FeedChallengeRarity.rare;
    case AchievementRarity.epic:
      return FeedChallengeRarity.epic;
    case AchievementRarity.legendary:
      return FeedChallengeRarity.legendary;
  }
}
