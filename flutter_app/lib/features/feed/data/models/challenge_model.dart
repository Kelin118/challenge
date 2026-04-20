import '../../domain/feed_challenge.dart';
import 'participation_model.dart';
import 'submission_model.dart';

class ChallengeModel {
  const ChallengeModel({
    required this.id,
    required this.creatorUserId,
    required this.creatorUsername,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.rarity,
    required this.coinCost,
    required this.coinReward,
    required this.creatorRewardPercent,
    required this.proofType,
    required this.status,
    required this.conditionsText,
    required this.successCriteriaText,
    required this.proofInstructions,
    required this.deadlineLabel,
    required this.participantsCount,
    required this.completedCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int creatorUserId;
  final String creatorUsername;
  final String title;
  final String description;
  final String category;
  final String type;
  final String rarity;
  final int coinCost;
  final int coinReward;
  final int creatorRewardPercent;
  final String proofType;
  final String status;
  final String? conditionsText;
  final String? successCriteriaText;
  final String? proofInstructions;
  final String? deadlineLabel;
  final int participantsCount;
  final int completedCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: _asInt(json['id']),
      creatorUserId: _asInt(json['creatorUserId']),
      creatorUsername: json['creatorUsername'] as String? ?? '@creator',
      title: json['title'] as String? ?? 'Без названия',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Разное',
      type: json['type'] as String? ?? 'daily',
      rarity: json['rarity'] as String? ?? 'common',
      coinCost: _asInt(json['coinCost']),
      coinReward: _asInt(json['coinReward']),
      creatorRewardPercent: _asInt(json['creatorRewardPercent']),
      proofType: json['proofType'] as String? ?? 'photo',
      status: json['status'] as String? ?? 'active',
      conditionsText: json['conditionsText'] as String?,
      successCriteriaText: json['successCriteriaText'] as String?,
      proofInstructions: json['proofInstructions'] as String?,
      deadlineLabel: json['deadlineLabel'] as String?,
      participantsCount: _asInt(json['participantsCount']),
      completedCount: _asInt(json['completedCount']),
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  FeedChallenge toFeedChallenge({
    ParticipationModel? participation,
    SubmissionModel? submission,
    bool isLiked = false,
    bool isSaved = false,
    bool isFollowingAuthor = false,
  }) {
    final executionStatus = _mapExecutionStatus(participation, submission);
    final authorHandle = creatorUsername.startsWith('@') ? creatorUsername : '@$creatorUsername';
    final authorName = creatorUsername.startsWith('@') ? creatorUsername.substring(1) : creatorUsername;
    final hasMedal = rarity != 'common';
    final medalTitle = hasMedal ? 'Медаль ${_rarityLabel(_mapRarity(rarity)).toLowerCase()}' : '';

    return FeedChallenge(
      id: '$id',
      title: title,
      description: description,
      fullDescription: conditionsText?.trim().isNotEmpty == true ? conditionsText!.trim() : description,
      category: category,
      type: _mapType(type),
      rarity: _mapRarity(rarity),
      coinReward: coinReward,
      authorName: authorName.isEmpty ? 'Автор' : authorName,
      authorHandle: authorHandle,
      source: authorHandle == '@system' ? FeedChallengeSource.system : FeedChallengeSource.user,
      sourceTag: authorHandle == '@system' ? 'Система' : 'Авторский',
      likes: participantsCount + completedCount * 2,
      isAccepted: participation != null,
      isLiked: isLiked,
      isSaved: isSaved,
      isFollowingAuthor: isFollowingAuthor,
      isSystemGenerated: authorHandle == '@system',
      recommendedFor: [category],
      reason: authorHandle == '@system' ? 'Системный челлендж в общей витрине.' : 'Набирает движение в ленте сообщества.',
      progress: ((participation?.progressValue ?? 0) / 100).clamp(0, 1),
      participants: participantsCount,
      acceptedCount: participantsCount,
      completedCount: completedCount,
      rules: _splitBulletLikeText(proofInstructions) ?? const ['Собери понятный результат и отправь proof.'],
      successCriteria: _splitBulletLikeText(successCriteriaText) ?? const ['Результат должен быть понятен и подтверждаем.'],
      limitations: deadlineLabel?.trim().isNotEmpty == true
          ? 'Срок: ${deadlineLabel!.trim()}'
          : 'Соблюдай условия челленджа и формат подтверждения.',
      deadlineLabel: deadlineLabel?.trim().isNotEmpty == true ? deadlineLabel!.trim() : 'Без жёсткого дедлайна',
      hasMedal: hasMedal,
      medalTitle: medalTitle,
      specialStatus: creatorRewardPercent > 0
          ? 'Создатель получает $creatorRewardPercent% с подтверждённых выполнений.'
          : 'Награда приходит после подтверждения выполнения.',
      creatorChallengeCount: 0,
      creatorCommissionPercent: creatorRewardPercent,
      verificationType: _mapVerificationType(proofType),
      executionStatus: executionStatus,
      submissionText: submission?.comment ?? '',
      submissionImagePath: submission?.proofUrl,
      rejectionReason: submission?.rejectionReason,
      medalAwarded: executionStatus == FeedExecutionStatus.approved && hasMedal,
      completionLikes: 0,
    );
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

FeedChallengeType _mapType(String value) {
  switch (value) {
    case 'yearly':
      return FeedChallengeType.yearly;
    case 'permanent':
      return FeedChallengeType.permanent;
    default:
      return FeedChallengeType.daily;
  }
}

FeedChallengeRarity _mapRarity(String value) {
  switch (value) {
    case 'rare':
      return FeedChallengeRarity.rare;
    case 'epic':
      return FeedChallengeRarity.epic;
    case 'legendary':
      return FeedChallengeRarity.legendary;
    case 'mythic':
      return FeedChallengeRarity.mythic;
    default:
      return FeedChallengeRarity.common;
  }
}

String _rarityLabel(FeedChallengeRarity rarity) {
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

FeedVerificationType _mapVerificationType(String value) {
  switch (value) {
    case 'text':
      return FeedVerificationType.text;
    case 'community':
      return FeedVerificationType.community;
    case 'moderator':
      return FeedVerificationType.moderator;
    case 'system':
      return FeedVerificationType.system;
    default:
      return FeedVerificationType.photo;
  }
}

FeedExecutionStatus _mapExecutionStatus(ParticipationModel? participation, SubmissionModel? submission) {
  final submissionStatus = submission?.status;
  if (submissionStatus == 'accepted') return FeedExecutionStatus.approved;
  if (submissionStatus == 'rejected') return FeedExecutionStatus.rejected;
  if (submissionStatus == 'pending') return FeedExecutionStatus.submitted;

  final participationStatus = participation?.status;
  switch (participationStatus) {
    case 'in_progress':
      return FeedExecutionStatus.inProgress;
    case 'submitted':
      return FeedExecutionStatus.submitted;
    case 'approved':
      return FeedExecutionStatus.approved;
    case 'rejected':
      return FeedExecutionStatus.rejected;
    default:
      return FeedExecutionStatus.notAccepted;
  }
}

List<String>? _splitBulletLikeText(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value
      .split(RegExp(r'[\n•;]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}



