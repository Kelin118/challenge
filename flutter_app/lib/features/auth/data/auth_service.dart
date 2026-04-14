import 'dart:io' show Platform;

import '../../../core/constants/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/token_storage.dart';
import '../../sessions/domain/device_session.dart';
import '../domain/auth_user.dart';

class AuthLoginResult {
  const AuthLoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}

class AuthService {
  AuthService({
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage() {
    _apiClient = ApiClient(
      accessTokenProvider: _tokenStorage.readAccessToken,
      refreshTokenProvider: _tokenStorage.readRefreshToken,
      refreshAccessToken: _refreshAccessTokenFromStoredContext,
      onUnauthorized: _handleUnauthorized,
    );
  }

  final TokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  Future<void> Function()? _onUnauthorized;

  String get baseUrl => AppConfig.baseUrl;
  ApiClient get apiClient => _apiClient;

  void setUnauthorizedHandler(Future<void> Function() handler) {
    _onUnauthorized = handler;
  }

  Future<String?> getAccessToken() => _tokenStorage.readAccessToken();

  Future<String?> getRefreshToken() => _tokenStorage.readRefreshToken();

  Future<void> clearTokens() => _tokenStorage.clearTokens();

  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    await _apiClient.postJson(
      baseUrl: baseUrl,
      path: '/api/auth/register',
      body: {
        'email': email.trim().toLowerCase(),
        'username': username.trim(),
        'password': password,
      },
    );
  }

  Future<AuthLoginResult> login({
    required String login,
    required String password,
  }) async {
    final normalized = login.trim();
    final isEmail = normalized.contains('@');
    final platform = _resolvePlatform();
    final deviceName = _resolveDeviceName(platform);

    final response = await _apiClient.postJson(
      baseUrl: baseUrl,
      path: '/api/auth/login',
      body: {
        if (isEmail) 'email': normalized.toLowerCase() else 'username': normalized,
        'password': password,
        'platform': platform,
        'device_name': deviceName,
      },
    );

    final accessToken = response['accessToken'] as String?;
    final refreshToken = response['refreshToken'] as String?;
    final userJson = response['user'] as Map<String, dynamic>?;

    if (accessToken == null || refreshToken == null || userJson == null) {
      throw const AppException('пїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ.');
    }

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return AuthLoginResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AuthUser.fromJson(userJson),
    );
  }

  Future<AuthUser?> restoreSession() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearTokens();
      return null;
    }

    try {
      final refreshedAccessToken = await _refreshAccessTokenFromStoredContext(refreshToken);
      if (refreshedAccessToken == null || refreshedAccessToken.isEmpty) {
        await clearTokens();
        return null;
      }

      return fetchCurrentUser();
    } on UnauthorizedException {
      await clearTokens();
      return null;
    } on AppException {
      await clearTokens();
      return null;
    }
  }

  Future<AuthUser> fetchCurrentUser() async {
    final response = await _apiClient.getJson(
      baseUrl: baseUrl,
      path: '/api/auth/me',
      authorized: true,
    );

    final userJson = response['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      throw const AppException('пїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ.');
    }

    return AuthUser.fromJson(userJson);
  }

  Future<List<DeviceSession>> fetchActiveSessions() async {
    final response = await _apiClient.getJson(
      baseUrl: baseUrl,
      path: '/api/auth/sessions',
      authorized: true,
    );

    final sessionsJson = response['sessions'] as List<dynamic>?;
    if (sessionsJson == null) {
      return const [];
    }

    return sessionsJson
        .whereType<Map<String, dynamic>>()
        .map(DeviceSession.fromJson)
        .toList();
  }

  Future<void> logoutSession({
    required int sessionId,
  }) async {
    await _apiClient.postJson(
      baseUrl: baseUrl,
      path: '/api/auth/logout-session',
      body: {'sessionId': sessionId},
      authorized: true,
    );
  }

  Future<void> logoutAllSessions() async {
    await _apiClient.postJson(
      baseUrl: baseUrl,
      path: '/api/auth/logout-all',
      body: const {},
      authorized: true,
    );
  }

  Future<String?> _refreshAccessTokenFromStoredContext(String refreshToken) async {
    final refreshClient = ApiClient(
      accessTokenProvider: _tokenStorage.readAccessToken,
      refreshTokenProvider: _tokenStorage.readRefreshToken,
      refreshAccessToken: (_) async => null,
      onUnauthorized: () async {},
    );

    final response = await refreshClient.postJson(
      baseUrl: baseUrl,
      path: '/api/auth/refresh',
      body: {'refreshToken': refreshToken},
    );

    final accessToken = response['accessToken'] as String?;
    final nextRefreshToken = response['refreshToken'] as String?;

    if (accessToken == null ||
        accessToken.isEmpty ||
        nextRefreshToken == null ||
        nextRefreshToken.isEmpty) {
      throw const AppException('пїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅ.');
    }

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: nextRefreshToken,
    );

    return accessToken;
  }

  Future<void> _handleUnauthorized() async {
    await clearTokens();
    final callback = _onUnauthorized;
    if (callback != null) {
      await callback();
    }
  }

  String _resolvePlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  String _resolveDeviceName(String platform) {
    switch (platform) {
      case 'android':
        return 'Android device';
      case 'ios':
        return 'iPhone';
      case 'windows':
        return 'Windows';
      case 'macos':
        return 'macOS';
      case 'linux':
        return 'Linux';
      default:
        return 'Unknown device';
    }
  }
}

