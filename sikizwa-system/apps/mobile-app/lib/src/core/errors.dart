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
  ApiException({required ApiError error})
      : statusCode = error.statusCode,
        details = error.details,
        super(error.message);

  final int statusCode;
  final String? details;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

String formatError(Object error) {
  if (error is AppException) {
    return error.message;
  }

  if (error is String) {
    return error;
  }

  return error.toString();
}
