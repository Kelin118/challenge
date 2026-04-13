import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({
    required Future<String?> Function() accessTokenProvider,
    required Future<String?> Function() refreshTokenProvider,
    required Future<String?> Function(String refreshToken) refreshAccessToken,
    required Future<void> Function() onUnauthorized,
    http.Client? httpClient,
  })  : _accessTokenProvider = accessTokenProvider,
        _refreshTokenProvider = refreshTokenProvider,
        _refreshAccessToken = refreshAccessToken,
        _onUnauthorized = onUnauthorized,
        _httpClient = httpClient ?? http.Client();

  final Future<String?> Function() _accessTokenProvider;
  final Future<String?> Function() _refreshTokenProvider;
  final Future<String?> Function(String refreshToken) _refreshAccessToken;
  final Future<void> Function() _onUnauthorized;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> getJson({
    required String baseUrl,
    required String path,
    bool authorized = false,
  }) {
    return _request(
      method: 'GET',
      baseUrl: baseUrl,
      path: path,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> postJson({
    required String baseUrl,
    required String path,
    required Map<String, dynamic> body,
    bool authorized = false,
  }) {
    return _request(
      method: 'POST',
      baseUrl: baseUrl,
      path: path,
      body: body,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> patchJson({
    required String baseUrl,
    required String path,
    required Map<String, dynamic> body,
    bool authorized = false,
  }) {
    return _request(
      method: 'PATCH',
      baseUrl: baseUrl,
      path: path,
      body: body,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String baseUrl,
    required String path,
    Map<String, dynamic>? body,
    bool authorized = false,
    bool retryOnUnauthorized = true,
  }) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authorized) {
      final accessToken = await _accessTokenProvider();
      if (accessToken == null || accessToken.isEmpty) {
        throw const UnauthorizedException('����� ����������� �����������');
      }
      headers['Authorization'] = 'Bearer $accessToken';
    }

    late final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _httpClient.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _httpClient.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          );
          break;
        case 'PATCH':
          response = await _httpClient.patch(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          );
          break;
        default:
          throw const AppException('���������������� HTTP �����');
      }
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    if (response.statusCode == 401 && authorized) {
      if (retryOnUnauthorized && await _tryRefreshAccessToken()) {
        return _request(
          method: method,
          baseUrl: baseUrl,
          path: path,
          body: body,
          authorized: authorized,
          retryOnUnauthorized: false,
        );
      }

      throw UnauthorizedException(_extractErrorMessage(response.body));
    }

    if (response.statusCode == 403) {
      throw ForbiddenException(_extractErrorMessage(response.body));
    }

    if (response.statusCode >= 400) {
      throw AppException(
        _extractErrorMessage(response.body),
        statusCode: response.statusCode,
      );
    }

    if (response.body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AppException('������������ ����� �������');
    }

    if (decoded['success'] == true) {
      final data = decoded['data'];
      if (data == null) {
        return const <String, dynamic>{};
      }
      if (data is Map<String, dynamic>) {
        return data;
      }
      return <String, dynamic>{'items': data};
    }

    throw AppException(
      _extractErrorMessage(response.body),
      statusCode: response.statusCode,
    );
  }

  Future<bool> _tryRefreshAccessToken() async {
    final refreshToken = await _refreshTokenProvider();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _onUnauthorized();
      return false;
    }

    try {
      final nextAccessToken = await _refreshAccessToken(refreshToken);
      if (nextAccessToken == null || nextAccessToken.isEmpty) {
        await _onUnauthorized();
        return false;
      }
      return true;
    } on UnauthorizedException {
      await _onUnauthorized();
      return false;
    } on AppException catch (error) {
      if (error.statusCode == 401) {
        await _onUnauthorized();
        return false;
      }
      rethrow;
    } catch (_) {
      await _onUnauthorized();
      return false;
    }
  }

  String _extractErrorMessage(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return '������ �������';
    }

    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message;
          }
        }

        final message = decoded['message'] ?? decoded['explanation'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignore parse issues and return raw body.
    }

    return rawBody;
  }
}
