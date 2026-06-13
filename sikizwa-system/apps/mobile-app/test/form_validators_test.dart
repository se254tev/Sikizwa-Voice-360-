import 'package:flutter_test/flutter_test.dart';
import 'package:sikizwa_mobile/src/core/validation/form_validators.dart';

void main() {
  group('FormValidators', () {
    test('returns a helpful message for missing login identifiers', () {
      final error = FormValidators.loginIdentifier('');

      expect(
        error,
        'Please enter your phone or username so we can sign you in.',
      );
    });

    test('flags invalid email addresses with guidance', () {
      final error = FormValidators.email('invalid-email');

      expect(
        error,
        'Please enter a valid email address (for example, name@example.com).',
      );
    });

    test('requires passwords to be at least 8 characters long', () {
      final error = FormValidators.password('1234567');

      expect(error, 'Password must be at least 8 characters long.');
    });

    test('accepts valid phone numbers for international use', () {
      final error = FormValidators.phone('+254712345678');

      expect(error, isNull);
    });

    test('rejects phone numbers with unsupported formatting', () {
      final error = FormValidators.phone('123-abc');

      expect(
        error,
        'Please enter a valid phone number using digits only, with an optional country code.',
      );
    });
  });
}
