import '../errors/auth_error_messages.dart';

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
      return AuthErrorMessages.messageFor(AuthErrorMessages.loginIdentifierRequired);
    }

    if (trimmed.length < 3) {
      return AuthErrorMessages.messageFor(AuthErrorMessages.loginIdentifierTooShort);
    }

    final normalizedPhone = trimmed.replaceAll(RegExp(r'[()\s-]'), '');
    final isPhone = RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalizedPhone);
    final isUsername = RegExp(r'^[A-Za-z0-9._@-]{3,}$').hasMatch(trimmed);

    if (!isPhone && !isUsername) {
      return AuthErrorMessages.messageFor(AuthErrorMessages.loginIdentifierInvalid);
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

  static String? otp(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty || !RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return AuthErrorMessages.messageFor(AuthErrorMessages.otpRequired);
    }

    return null;
  }

  static String? email(String? value, {bool required = false}) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      if (required) {
        return AuthErrorMessages.messageFor(AuthErrorMessages.invalidEmail);
      }

      return null;
    }

    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);

    if (!isValid) {
      return AuthErrorMessages.messageFor(AuthErrorMessages.invalidEmail);
    }

    return null;
  }

  static String? password(String? value, {bool required = false}) {
    final valueToCheck = value ?? '';

    if (valueToCheck.isEmpty) {
      if (required) {
        return AuthErrorMessages.messageFor(AuthErrorMessages.passwordRequired);
      }

      return null;
    }

    if (valueToCheck.length < 8) {
      return AuthErrorMessages.messageFor(AuthErrorMessages.passwordTooShort);
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(valueToCheck);
    final hasNumber = RegExp(r'[0-9]').hasMatch(valueToCheck);

    if (!hasUppercase || !hasNumber) {
      return AuthErrorMessages.messageFor(AuthErrorMessages.weakPassword);
    }

    return null;
  }

  static String? phone(String? value, {bool required = false}) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      if (required) {
        return AuthErrorMessages.messageFor(AuthErrorMessages.phoneRequired);
      }

      return null;
    }

    final normalized = trimmed.replaceAll(RegExp(r'[()\s-]'), '');

    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalized)) {
      return AuthErrorMessages.messageFor(AuthErrorMessages.phoneFormatInvalid);
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
