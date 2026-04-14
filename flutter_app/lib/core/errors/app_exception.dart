class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Не авторизован'])
      : super(statusCode: 401);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Доступ запрещён'])
      : super(statusCode: 403);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Не удалось подключиться к серверу']);
}
