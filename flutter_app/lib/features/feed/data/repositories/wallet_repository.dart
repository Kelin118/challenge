import '../../../../core/network/api_client.dart';
import '../../../auth/data/auth_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

class WalletRepository {
  WalletRepository(this._authService);

  final AuthService _authService;

  ApiClient get _apiClient => _authService.apiClient;
  String get _baseUrl => _authService.baseUrl;

  Future<WalletModel> fetchWallet() async {
    final response = await _apiClient.getJson(baseUrl: _baseUrl, path: '/api/wallet', authorized: true);
    final wallet = response['wallet'] as Map<String, dynamic>?;
    if (wallet == null) {
      throw const FormatException('Wallet payload is missing.');
    }

    return WalletModel.fromJson(wallet);
  }

  Future<List<TransactionModel>> fetchTransactions() async {
    final response = await _apiClient.getJson(baseUrl: _baseUrl, path: '/api/wallet/transactions', authorized: true);
    final items = response['transactions'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(TransactionModel.fromJson)
        .toList();
  }
}
