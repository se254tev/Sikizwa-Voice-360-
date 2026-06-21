import 'errors/auth_error_messages.dart';

class ApiError {
  const ApiError({
    required this.statusCode,
    required this.message,
    this.details,
  });

  final int statusCode;
  final String message;
  final String? details;
}

class AppException implements Exception {
  AppException(this.message);

  final String message;

  @override
  String toString() => 'AppException: $message';
}

class OfflineException extends AppException {
  OfflineException(String message) : super(message);
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}

class ApiException extends AppException {
  ApiException({
    ApiError? error,
    int? statusCode,
    String? message,
    String? details,
  })  : statusCode = error?.statusCode ?? statusCode ?? 500,
        details = details ?? error?.details,
        super(message ?? error?.message ?? AuthErrorMessages.malformedRequest);

  final int statusCode;
  final String? details;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

String formatError(Object error) {
  if (error is AppException) {
    return AuthErrorMessages.resolve(error.message);
  }

  if (error is String) {
    return AuthErrorMessages.resolve(error);
  }

  return error.toString();
}
