import 'package:flutter/foundation.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';

class WalletController extends ChangeNotifier {
  WalletController(this._authController, this._repository) {
    _authController.addListener(_handleAuthChanged);
  }

  final AuthController _authController;
  final WalletRepository _repository;

  WalletModel _wallet = const WalletModel.empty();
  List<TransactionModel> _transactions = const [];
  bool _isReady = false;
  bool _isLoading = false;
  String? _errorMessage;

  WalletModel get wallet => _wallet;
  List<TransactionModel> get transactions => _transactions;
  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCoins => _wallet.totalCoins;

  Future<void> load() async {
    if (!_authController.isAuthenticated) {
      _wallet = const WalletModel.empty();
      _transactions = const [];
      _isReady = true;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchWallet(),
        _repository.fetchTransactions(),
      ]);
      _wallet = results[0] as WalletModel;
      _transactions = results[1] as List<TransactionModel>;
      _isReady = true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _isReady = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleAuthChanged() {
    load();
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
