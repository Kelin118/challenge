import 'dart:async';
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

  static const Duration _requestTimeout = Duration(seconds: 15);

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

  Future<Map<String, dynamic>> postMultipart({
    required String baseUrl,
    required String path,
    required String filePath,
    String fileField = 'proof',
    Map<String, String> fields = const {},
    bool authorized = false,
  }) async {
    return _multipartRequest(
      baseUrl: baseUrl,
      path: path,
      filePath: filePath,
      fileField: fileField,
      fields: fields,
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
        throw const UnauthorizedException('Нужна авторизация пользователя');
      }
      headers['Authorization'] = 'Bearer $accessToken';
    }

    late final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _httpClient.get(uri, headers: headers).timeout(_requestTimeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body ?? const <String, dynamic>{}),
              )
              .timeout(_requestTimeout);
          break;
        case 'PATCH':
          response = await _httpClient
              .patch(
                uri,
                headers: headers,
                body: jsonEncode(body ?? const <String, dynamic>{}),
              )
              .timeout(_requestTimeout);
          break;
        default:
          throw const AppException('Неподдерживаемый HTTP метод');
      }
    } on TimeoutException {
      throw const NetworkException('Сервер не отвечает');
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    return _decodeResponse(
      response.statusCode,
      response.body,
      authorized: authorized,
      retryOnUnauthorized: retryOnUnauthorized,
      retry: () => _request(
        method: method,
        baseUrl: baseUrl,
        path: path,
        body: body,
        authorized: authorized,
        retryOnUnauthorized: false,
      ),
    );
  }

  Future<Map<String, dynamic>> _multipartRequest({
    required String baseUrl,
    required String path,
    required String filePath,
    required String fileField,
    required Map<String, String> fields,
    required bool authorized,
    bool retryOnUnauthorized = true,
  }) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path');
    final request = http.MultipartRequest('POST', uri)
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(fileField, filePath));

    if (authorized) {
      final accessToken = await _accessTokenProvider();
      if (accessToken == null || accessToken.isEmpty) {
        throw const UnauthorizedException('Нужна авторизация пользователя');
      }
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final streamed = await _httpClient.send(request).timeout(_requestTimeout);
      final response = await http.Response.fromStream(streamed);
      return _decodeResponse(
        response.statusCode,
        response.body,
        authorized: authorized,
        retryOnUnauthorized: retryOnUnauthorized,
        retry: () => _multipartRequest(
          baseUrl: baseUrl,
          path: path,
          filePath: filePath,
          fileField: fileField,
          fields: fields,
          authorized: authorized,
          retryOnUnauthorized: false,
        ),
      );
    } on TimeoutException {
      throw const NetworkException('Upload слишком долго не отвечает');
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  Future<Map<String, dynamic>> _decodeResponse(
    int statusCode,
    String body, {
    required bool authorized,
    required bool retryOnUnauthorized,
    required Future<Map<String, dynamic>> Function() retry,
  }) async {
    if (statusCode == 401 && authorized) {
      if (retryOnUnauthorized && await _tryRefreshAccessToken()) {
        return retry();
      }

      throw UnauthorizedException(_extractErrorMessage(body));
    }

    if (statusCode == 403) {
      throw ForbiddenException(_extractErrorMessage(body));
    }

    if (statusCode >= 400) {
      throw AppException(
        _extractErrorMessage(body),
        statusCode: statusCode,
      );
    }

    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AppException('Некорректный ответ сервера');
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
      _extractErrorMessage(body),
      statusCode: statusCode,
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
      return 'Ошибка сервера';
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
