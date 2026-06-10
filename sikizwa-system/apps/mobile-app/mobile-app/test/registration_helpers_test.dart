import 'package:flutter_test/flutter_test.dart';
import 'package:sikizwa_mobile/src/features/auth/registration_helpers.dart';

void main() {
  group('registration helpers', () {
    test('optional fields are normalized to null when blank', () {
      expect(normalizeOptionalField('   '), isNull);
      expect(normalizeOptionalField('  hello@example.com '), 'hello@example.com');
    });

    test('blank emergency contacts are omitted while complete contacts are kept', () {
      final result = filterCompletedEmergencyContacts([
        {'name': '', 'phone': '', 'relationship': ''},
        {'name': 'Amina', 'phone': '+27821234567', 'relationship': 'Sibling'},
      ]);

      expect(result, hasLength(1));
      expect(result.first['name'], 'Amina');
    });

    test('partial contacts are treated as invalid and complete contacts remain valid', () {
      expect(validateEmergencyContact({'name': 'Amina', 'phone': '', 'relationship': 'Sibling'}),
          'Complete all emergency contact fields before saving them.');
      expect(validateEmergencyContact({'name': 'Amina', 'phone': '+27821234567', 'relationship': 'Sibling'}),
          isNull);
    });
  });
}
