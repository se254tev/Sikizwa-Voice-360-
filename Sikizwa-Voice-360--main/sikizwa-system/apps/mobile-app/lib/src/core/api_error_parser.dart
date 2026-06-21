import 'errors/auth_error_messages.dart';

class ApiErrorParser {
  const ApiErrorParser._();

  static String errorKeyForResponse({
    required int statusCode,
    required dynamic body,
    required String path,
  }) {
    if (statusCode == 429) {
      return AuthErrorMessages.rateLimited;
    }

    if (statusCode == 408) {
      return AuthErrorMessages.connectionTimeout;
    }

    if (statusCode == 503) {
      return AuthErrorMessages.serverUnavailable;
    }

    final rawMessage = _extractBackendMessage(body);
    final lower = rawMessage.toLowerCase();

    if (path.contains('/auth/login')) {
      if (statusCode == 401 ||
          lower.contains('invalid') ||
          lower.contains('credential') ||
          lower.contains('username') ||
          lower.contains('password') ||
          lower.contains('required') ||
          lower.contains('identifier')) {
        return AuthErrorMessages.invalidCredentials;
      }

      return AuthErrorMessages.malformedRequest;
    }

    if (path.contains('/auth/register')) {
      if (lower.contains('password') && (lower.contains('at least 8') || lower.contains('letter') || lower.contains('number'))) {
        return AuthErrorMessages.weakPassword;
      }

      if (lower.contains('email') && lower.contains('valid')) {
        return AuthErrorMessages.invalidEmail;
      }

      if (lower.contains('phone') || lower.contains('international')) {
        return AuthErrorMessages.invalidPhone;
      }

      if (statusCode == 400 || statusCode == 409 || statusCode == 422) {
        return AuthErrorMessages.accountCreationFailed;
      }

      return AuthErrorMessages.malformedRequest;
    }

    if (path.contains('/auth/verify-otp')) {
      if (lower.contains('expired')) {
        return AuthErrorMessages.expiredOtp;
      }

      return AuthErrorMessages.invalidOtp;
    }

    if (path.contains('/auth/reset-password')) {
      if (lower.contains('password') && (lower.contains('at least 8') || lower.contains('letter') || lower.contains('number'))) {
        return AuthErrorMessages.weakPassword;
      }

      if (lower.contains('otp') || lower.contains('expired') || lower.contains('code')) {
        return AuthErrorMessages.expiredOtp;
      }

      if (statusCode == 401) {
        return AuthErrorMessages.sessionExpired;
      }

      return AuthErrorMessages.malformedRequest;
    }

    if (path.contains('/auth/forgot-password')) {
      if (lower.contains('phone') || lower.contains('number')) {
        return AuthErrorMessages.invalidPhone;
      }

      if (statusCode == 401) {
        return AuthErrorMessages.sessionExpired;
      }

      return AuthErrorMessages.malformedRequest;
    }

    if (statusCode == 401) {
      return AuthErrorMessages.sessionExpired;
    }

    if (statusCode == 400 || statusCode == 422) {
      return AuthErrorMessages.malformedRequest;
    }

    if (statusCode >= 500) {
      return AuthErrorMessages.serverUnavailable;
    }

    return AuthErrorMessages.malformedRequest;
  }

  static String _extractBackendMessage(dynamic body) {
    if (body == null) {
      return '';
    }

    if (body is Map) {
      for (final key in ['message', 'error', 'detail', 'errors', 'msg', 'description']) {
        final value = body[key];
        if (value != null) {
          return value.toString();
        }
      }

      return body.toString();
    }

    if (body is String) {
      return body;
    }

    if (body is List) {
      if (body.isEmpty) {
        return '';
      }

      return body.map((item) => item.toString()).join(', ');
    }

    return body.toString();
  }
}
