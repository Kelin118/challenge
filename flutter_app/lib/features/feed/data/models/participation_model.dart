class ParticipationModel {
  const ParticipationModel({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.status,
    required this.progressValue,
    required this.acceptedAt,
    required this.submittedAt,
    required this.approvedAt,
    required this.rejectedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int challengeId;
  final int userId;
  final String status;
  final int progressValue;
  final DateTime? acceptedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ParticipationModel.fromJson(Map<String, dynamic> json) {
    return ParticipationModel(
      id: _asInt(json['id']),
      challengeId: _asInt(json['challengeId']),
      userId: _asInt(json['userId']),
      status: json['status'] as String? ?? 'not_accepted',
      progressValue: _asInt(json['progressValue']),
      acceptedAt: _asDateTime(json['acceptedAt']),
      submittedAt: _asDateTime(json['submittedAt']),
      approvedAt: _asDateTime(json['approvedAt']),
      rejectedAt: _asDateTime(json['rejectedAt']),
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
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
