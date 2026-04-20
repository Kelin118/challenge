class WalletModel {
  const WalletModel({
    required this.totalCoins,
    required this.earnedCoins,
    required this.spentCoins,
  });

  final int totalCoins;
  final int earnedCoins;
  final int spentCoins;

  const WalletModel.empty()
      : totalCoins = 0,
        earnedCoins = 0,
        spentCoins = 0;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      totalCoins: _asInt(json['totalCoins']),
      earnedCoins: _asInt(json['earnedCoins']),
      spentCoins: _asInt(json['spentCoins']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
