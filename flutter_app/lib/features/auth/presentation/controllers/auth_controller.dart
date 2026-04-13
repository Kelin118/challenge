import 'package:flutter/foundation.dart';

import '../../data/auth_service.dart';
import '../../domain/auth_user.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authService) {
    _authService.setUnauthorizedHandler(_handleUnauthorized);
  }

  final AuthService _authService;

  bool _isReady = false;
  bool _isLoading = false;
  AuthUser? _currentUser;

  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> load() async {
    _currentUser = await _authService.restoreSession();
    _isReady = true;
    notifyListeners();
  }

  Future<void> login({
    required String login,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(
        login: login,
        password: password,
      );
      _currentUser = result.user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.register(
        email: email,
        username: username,
        password: password,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.clearTokens();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _handleUnauthorized() async {
    _currentUser = null;
    notifyListeners();
  }
}
