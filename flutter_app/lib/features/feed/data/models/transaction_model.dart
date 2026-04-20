class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.submissionId,
    required this.transactionType,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final int? challengeId;
  final int? submissionId;
  final String transactionType;
  final int amount;
  final String description;
  final DateTime? createdAt;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: _asInt(json['id']),
      userId: _asInt(json['userId']),
      challengeId: _nullableInt(json['challengeId']),
      submissionId: _nullableInt(json['submissionId']),
      transactionType: json['transactionType'] as String? ?? 'unknown',
      amount: _asInt(json['amount']),
      description: json['description'] as String? ?? '',
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
  return int.tryParse('$value');
}

DateTime? _asDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
