class FormValidators {
  const FormValidators._();

  static String? required(String? value, {required String fieldLabel}) {
    final trimmed = value?.trim() ?? '';
    final normalizedFieldLabel = fieldLabel.toLowerCase();

    if (trimmed.isEmpty) {
      return 'Enter your $normalizedFieldLabel to continue.';
    }

    return null;
  }

  static String? loginIdentifier(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return 'Enter your phone or username to sign in.';
    }

    if (trimmed.length < 3) {
      return 'Enter at least 3 characters for your phone or username.';
    }

    final normalizedPhone = trimmed.replaceAll(RegExp(r'[()\s-]'), '');
    final isPhone = RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalizedPhone);
    final isUsername = RegExp(r'^[A-Za-z0-9._@-]{3,}$').hasMatch(trimmed);

    if (!isPhone && !isUsername) {
      return 'Enter a valid phone number or username.';
    }

    return null;
  }

  static String? name(String? value, {required String fieldLabel}) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return 'Enter your $fieldLabel to continue.';
    }

    if (trimmed.length < 2) {
      return 'Enter at least 2 characters for $fieldLabel.';
    }

    return null;
  }

  static String? email(String? value, {bool required = false}) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      if (required) {
        return 'Enter a valid email address (example, name@example.com).';
      }

      return null;
    }

    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);

    if (!isValid) {
      return 'Enter a valid email address (example, name@example.com).';
    }

    return null;
  }

  static String? password(String? value, {bool required = false}) {
    final valueToCheck = value ?? '';

    if (valueToCheck.isEmpty) {
      if (required) {
        return 'Create password.';
      }

      return null;
    }

    if (valueToCheck.length < 8) {
      return 'Password must be at least 8 characters long.';
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(valueToCheck);
    final hasNumber = RegExp(r'[0-9]').hasMatch(valueToCheck);

    if (!hasUppercase || !hasNumber) {
      return 'Use at least 8 characters, including one uppercase letter and one number.';
    }

    return null;
  }

  static String? phone(String? value, {bool required = false}) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      if (required) {
        return 'Enter your phone number.';
      }

      return null;
    }

    final normalized = trimmed.replaceAll(RegExp(r'[()\s-]'), '');

    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalized)) {
      return 'Enter a valid phone number using digits only, with an optional country code.';
    }

    return null;
  }

  static String? relationship(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return 'Please tell us how this contact is related to you.';
    }

    if (trimmed.length < 2) {
      return 'Relationship must be at least 2 characters long.';
    }

    return null;
  }

  static String? optionalText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return null;
  }

  static String? fullName(String? value) {
    return name(value, fieldLabel: 'full name');
  }
}
