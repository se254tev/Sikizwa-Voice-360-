class ApiErrorParser {
  const ApiErrorParser._();

  static String userMessageForResponse({
    required int statusCode,
    required dynamic body,
    required String path,
  }) {
    if (statusCode == 429) {
      return 'Too many requests. Please try again later.';
    }

    if (statusCode == 408) {
      return 'Connection is taking longer than expected.';
    }

    if (statusCode == 503) {
      return 'Server is starting. Please wait a moment.';
    }

    final rawMessage = _extractBackendMessage(body);
    final normalizedMessage = _normalizeMessage(rawMessage, path: path);

    if (normalizedMessage != null && normalizedMessage.isNotEmpty) {
      return normalizedMessage;
    }

    return _fallbackMessage(statusCode);
  }

  static String? _extractBackendMessage(dynamic body) {
    if (body == null) {
      return null;
    }

    if (body is Map) {
      for (final key in ['message', 'error', 'detail', 'errors', 'msg', 'description']) {
        final value = body[key];
        if (value != null) {
          return value.toString();
        }
      }
    }

    if (body is String) {
      return body;
    }

    if (body is List) {
      if (body.isEmpty) {
        return null;
      }
      return body.map((item) => item.toString()).join(', ');
    }

    return body.toString();
  }

  static String? _normalizeMessage(String? message, {required String path}) {
    if (message == null) {
      return null;
    }

    final cleaned = message
        .replaceAll(RegExp(r'^\s+|\s+$'), '')
        .replaceAll(RegExp(r'^body\.'), '')
        .replaceAll('"', '')
        .trim();

    final lower = cleaned.toLowerCase();

    if (lower.isEmpty) {
      return null;
    }

    if (lower.contains('server is starting')) {
      return 'Server is starting. Please wait a moment.';
    }

    if (lower.contains('timeout')) {
      return 'Connection is taking longer than expected.';
    }

    if (lower.contains('too many requests')) {
      return 'Too many requests. Please try again later.';
    }

    if (path.contains('/auth/login') && lower == 'invalid') {
      return 'Invalid username or password.';
    }

    if (path.contains('/auth/login') && lower.contains('username and password required')) {
      return 'Please enter a username and password.';
    }

    if (path.contains('/auth/register') && lower.contains('username and password required')) {
      return 'Please enter a username and password.';
    }

    if (lower.contains('password') && lower.contains('at least 8')) {
      return 'Password must be at least 8 characters long.';
    }

    if (lower.contains('username') && lower.contains('at least 3')) {
      return 'Username must be at least 3 characters long.';
    }

    if (lower.contains('audio file required') || lower.contains('audio file')) {
      return 'Please choose an audio file to upload.';
    }

    if (lower.contains('token required')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (lower.contains('message required') || lower.contains('missing message')) {
      return 'Please enter a message before sending.';
    }

    if (lower.contains('file required')) {
      return 'Please choose a file to upload.';
    }

    return cleaned;
  }

  static String _fallbackMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'Your request was rejected. Please sign in again or retry.';
      case 404:
        return 'The requested resource could not be found.';
      case 422:
        return 'The request data is invalid. Please review your inputs.';
      case 500:
        return 'The server is currently unavailable. Please try again.';
      default:
        return 'The request could not be completed. Please review your input and try again.';
    }
  }
}
