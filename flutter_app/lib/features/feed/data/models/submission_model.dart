class SubmissionModel {
  const SubmissionModel({
    required this.id,
    required this.challengeId,
    required this.participationId,
    required this.userId,
    required this.proofUrl,
    required this.proofType,
    required this.comment,
    required this.status,
    required this.rejectionReason,
    required this.rewardGrantedAt,
    required this.reviewedByUserId,
    required this.reviewedAt,
    required this.createdAt,
  });

  final int id;
  final int challengeId;
  final int participationId;
  final int userId;
  final String? proofUrl;
  final String proofType;
  final String? comment;
  final String status;
  final String? rejectionReason;
  final DateTime? rewardGrantedAt;
  final int? reviewedByUserId;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: _asInt(json['id']),
      challengeId: _asInt(json['challengeId']),
      participationId: _asInt(json['participationId']),
      userId: _asInt(json['userId']),
      proofUrl: json['proofUrl'] as String?,
      proofType: json['proofType'] as String? ?? 'photo',
      comment: json['comment'] as String?,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejectionReason'] as String?,
      rewardGrantedAt: _asDateTime(json['rewardGrantedAt']),
      reviewedByUserId: _nullableInt(json['reviewedByUserId']),
      reviewedAt: _asDateTime(json['reviewedAt']),
      createdAt: _asDateTime(json['createdAt']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  final parsed = int.tryParse('$value');
  return parsed;
}

DateTime? _asDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
