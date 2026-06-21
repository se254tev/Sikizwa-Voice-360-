class RegistrationHelpers {
  const RegistrationHelpers._();

  static String? normalizeOptionalField(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<Map<String, String>> filterCompletedEmergencyContacts(
    List<Map<String, String>> contacts,
  ) {
    return contacts.where((contact) {
      final name = contact['name']?.trim() ?? '';
      final phone = contact['phone']?.trim() ?? '';
      final relationship = contact['relationship']?.trim() ?? '';
      return name.isNotEmpty && phone.isNotEmpty && relationship.isNotEmpty;
    }).toList();
  }

  static String? validateEmergencyContact(Map<String, String> contact) {
    final name = contact['name']?.trim() ?? '';
    final phone = contact['phone']?.trim() ?? '';
    final relationship = contact['relationship']?.trim() ?? '';

    if (name.isEmpty && phone.isEmpty && relationship.isEmpty) {
      return null;
    }

    if (name.isEmpty || phone.isEmpty || relationship.isEmpty) {
      return 'Complete all emergency contact fields before saving them.';
    }

    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
      return 'Emergency contact phone numbers must be valid international numbers.';
    }

    return null;
  }
}

String? normalizeOptionalField(String? value) => RegistrationHelpers.normalizeOptionalField(value);

List<Map<String, String>> filterCompletedEmergencyContacts(
  List<Map<String, String>> contacts,
) =>
    RegistrationHelpers.filterCompletedEmergencyContacts(contacts);

String? validateEmergencyContact(Map<String, String> contact) =>
    RegistrationHelpers.validateEmergencyContact(contact);
