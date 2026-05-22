class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}

class ApiException extends AppException {
  final int statusCode;
  ApiException({required this.statusCode, String message = 'API Error'}) : super(message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
