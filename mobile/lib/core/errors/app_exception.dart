class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AppException(statusCode: $statusCode, code: $code, message: $message)';
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.details});
}

class AuthException extends AppException {
  const AuthException({required super.message, super.statusCode, super.code});
}

class ApiException extends AppException {
  const ApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
  });
}

class WalletException extends AppException {
  const WalletException({required super.message, super.code, super.details});
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.details});
}
