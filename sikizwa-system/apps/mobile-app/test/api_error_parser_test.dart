import 'package:flutter_test/flutter_test.dart';
import 'package:sikizwa_mobile/src/core/api_error_parser.dart';
import 'package:sikizwa_mobile/src/core/errors.dart';

void main() {
  group('ApiErrorParser', () {
    test('maps login validation errors to readable messages', () {
      final message = ApiErrorParser.userMessageForResponse(
        statusCode: 400,
        body: {'error': 'username and password required'},
        path: '/api/auth/login',
      );

      expect(message, 'Please enter a username and password.');
    });

    test('maps invalid login credentials to a friendly message', () {
      final message = ApiErrorParser.userMessageForResponse(
        statusCode: 401,
        body: {'error': 'invalid'},
        path: '/api/auth/login',
      );

      expect(message, 'Invalid username or password.');
    });

    test('maps password validation failures to readable guidance', () {
      final message = ApiErrorParser.userMessageForResponse(
        statusCode: 422,
        body: {'error': '"password" length must be at least 8 characters long'},
        path: '/api/auth/register',
      );

      expect(message, 'Password must be at least 8 characters long.');
    });

    test('falls back to a generic message when the backend returns no details', () {
      final message = ApiErrorParser.userMessageForResponse(
        statusCode: 400,
        body: null,
        path: '/api/ai/chat',
      );

      expect(message, 'The request could not be completed. Please review your input and try again.');
    });
  });

  group('ApiError', () {
    test('preserves structured metadata for UI and logging', () {
      const error = ApiError(
        statusCode: 401,
        message: 'Your session has expired. Please sign in again.',
        details: 'token expired',
      );

      expect(error.statusCode, 401);
      expect(error.message, 'Your session has expired. Please sign in again.');
      expect(error.details, 'token expired');
    });
  });
}
