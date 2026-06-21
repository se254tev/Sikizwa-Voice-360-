import 'package:flutter_test/flutter_test.dart';
import 'package:sikizwa_mobile/src/core/api_error_parser.dart';
import 'package:sikizwa_mobile/src/core/errors.dart';
import 'package:sikizwa_mobile/src/core/errors/auth_error_messages.dart';

void main() {
  group('ApiErrorParser', () {
    test('maps login validation errors to normalized auth keys', () {
      final key = ApiErrorParser.errorKeyForResponse(
        statusCode: 400,
        body: {'error': 'username and password required'},
        path: '/api/auth/login',
      );

      expect(key, AuthErrorMessages.invalidCredentials);
    });

    test('maps invalid login credentials to a normalized auth key', () {
      final key = ApiErrorParser.errorKeyForResponse(
        statusCode: 401,
        body: {'error': 'invalid'},
        path: '/api/auth/login',
      );

      expect(key, AuthErrorMessages.invalidCredentials);
    });

    test('maps weak password failures to a validation key', () {
      final key = ApiErrorParser.errorKeyForResponse(
        statusCode: 422,
        body: {'error': '"password" length must be at least 8 characters long'},
        path: '/api/auth/register',
      );

      expect(key, AuthErrorMessages.weakPassword);
    });

    test('falls back to a malformed request key when the backend returns no details', () {
      final key = ApiErrorParser.errorKeyForResponse(
        statusCode: 400,
        body: null,
        path: '/api/ai/chat',
      );

      expect(key, AuthErrorMessages.malformedRequest);
    });

    test('maps server start-up responses to the server unavailable key', () {
      final key = ApiErrorParser.errorKeyForResponse(
        statusCode: 503,
        body: {'message': 'Server is starting'},
        path: '/api/auth/login',
      );

      expect(key, AuthErrorMessages.serverUnavailable);
    });

    test('maps timeout responses to the connection timeout key', () {
      final key = ApiErrorParser.errorKeyForResponse(
        statusCode: 408,
        body: {'message': 'Timeout'},
        path: '/api/auth/register',
      );

      expect(key, AuthErrorMessages.connectionTimeout);
    });

    test('maps rate-limited responses to the rate limited key', () {
      final key = ApiErrorParser.errorKeyForResponse(
        statusCode: 429,
        body: {'message': 'Too many requests. Please try again later.'},
        path: '/api/auth/login',
      );

      expect(key, AuthErrorMessages.rateLimited);
    });
  });

  group('ApiError', () {
    test('preserves structured metadata for UI and logging', () {
      const error = ApiError(
        statusCode: 401,
        message: AuthErrorMessages.sessionExpired,
        details: 'token expired',
      );

      expect(error.statusCode, 401);
      expect(error.message, AuthErrorMessages.sessionExpired);
      expect(error.details, 'token expired');
    });
  });
}
