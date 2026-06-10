class AuthErrorMessages {
  const AuthErrorMessages._();

  static const String invalidCredentials = 'invalidCredentials';
  static const String accountCreationFailed = 'accountCreationFailed';
  static const String sessionExpired = 'sessionExpired';
  static const String rateLimited = 'rateLimited';
  static const String requiredField = 'requiredField';
  static const String invalidPhone = 'invalidPhone';
  static const String phoneFormatInvalid = 'phoneFormatInvalid';
  static const String weakPassword = 'weakPassword';
  static const String invalidEmail = 'invalidEmail';
  static const String invalidOtp = 'invalidOtp';
  static const String expiredOtp = 'expiredOtp';
  static const String serverUnavailable = 'serverUnavailable';
  static const String connectionTimeout = 'connectionTimeout';
  static const String malformedRequest = 'malformedRequest';
  static const String loginIdentifierRequired = 'loginIdentifierRequired';
  static const String loginIdentifierTooShort = 'loginIdentifierTooShort';
  static const String loginIdentifierInvalid = 'loginIdentifierInvalid';
  static const String phoneRequired = 'phoneRequired';
  static const String passwordRequired = 'passwordRequired';
  static const String passwordTooShort = 'passwordTooShort';
  static const String otpRequired = 'otpRequired';
  static const String credentialsRequired = 'credentialsRequired';
  static const String pairingRequired = 'pairingRequired';
  static const String resetCodeSent = 'resetCodeSent';
  static const String otpVerified = 'otpVerified';
  static const String passwordUpdated = 'passwordUpdated';
  static const String fullNameRequired = 'fullNameRequired';
  static const String fullNameTooShort = 'fullNameTooShort';
  static const String deviceInfoUnavailable = 'deviceInfoUnavailable';

  static const Map<String, String> _messages = {
    invalidCredentials: 'Invalid credentials',
    accountCreationFailed: 'Unable to create account. Please try again.',
    sessionExpired: 'Your session has expired. Please sign in again.',
    rateLimited: 'Too many requests. Please try again later.',
    requiredField: 'This field is required.',
    invalidPhone: 'Please enter a valid phone number.',
    phoneFormatInvalid: 'Please enter a valid phone number using digits only, with an optional country code.',
    weakPassword: 'Use at least 8 characters, including one uppercase letter and one number.',
    invalidEmail: 'Please enter a valid email address (for example, name@example.com).',
    invalidOtp: 'Invalid verification code',
    expiredOtp: 'Invalid verification code',
    serverUnavailable: 'Something went wrong. Please try again.',
    connectionTimeout: 'Connection is taking longer than expected.',
    malformedRequest: 'Something went wrong. Please try again.',
    loginIdentifierRequired: 'Please enter your phone or username so we can sign you in.',
    loginIdentifierTooShort: 'Enter at least 3 characters for your phone or username.',
    loginIdentifierInvalid: 'Enter a valid phone number or username.',
    phoneRequired: 'Enter your phone number.',
    passwordRequired: 'Create password.',
    passwordTooShort: 'Password must be at least 8 characters long.',
    otpRequired: 'Enter the 6-digit verification code.',
    credentialsRequired: 'Please enter a valid phone number and password.',
    pairingRequired: 'Please enter the pairing code, phone, and password.',
    resetCodeSent: 'If the account exists, a reset code has been sent.',
    otpVerified: 'OTP verified. Choose a new password.',
    passwordUpdated: 'Password updated successfully.',
    fullNameRequired: 'Enter your full name to continue.',
    fullNameTooShort: 'Enter at least 2 characters for full name.',
    deviceInfoUnavailable: 'Device information is not available. Please reopen the app and try again.',
  };

  static const Map<String, String> _legacyTextToKey = {
    'Connection is taking longer than expected.': connectionTimeout,
    'No internet connection. Please check your network and try again.': serverUnavailable,
    'Server is starting. Please wait a moment.': serverUnavailable,
    'The authentication service returned an invalid response. Please try again.': malformedRequest,
    'The request could not be completed. Please review your input and try again.': malformedRequest,
    'Please enter the 6-digit verification code.': otpRequired,
    'Invalid credentials.': invalidCredentials,
    'Unable to create account. Please try again.': accountCreationFailed,
    'Your session has expired. Please sign in again.': sessionExpired,
    'Password must be at least 8 characters long.': passwordTooShort,
    'Please enter a valid email address (for example, name@example.com).': invalidEmail,
    'Please enter a valid phone number using digits only, with an optional country code.': phoneFormatInvalid,
    'Enter your phone number.': phoneRequired,
    'Please enter a valid phone number.': invalidPhone,
    'Phone number must be a valid international number.': invalidPhone,
    'Password must include at least one letter and one number.': weakPassword,
    'Invalid or expired code.': invalidOtp,
    'Invalid verification code': invalidOtp,
    'Create password.': passwordRequired,
    'If the account exists, a reset code has been sent': resetCodeSent,
    'OTP verified. Choose a new password.': otpVerified,
    'Password updated successfully.': passwordUpdated,
    'Enter your full name to continue.': fullNameRequired,
    'Enter at least 2 characters for full name.': fullNameTooShort,
    'Device information is not available. Please reopen the app and try again.': deviceInfoUnavailable,
  };

  static bool isKnownKey(String value) => _messages.containsKey(value);

  static String resolve(String value) {
    if (isKnownKey(value)) {
      return _messages[value]!;
    }

    final legacyKey = _legacyTextToKey[value];
    if (legacyKey != null) {
      return _messages[legacyKey]!;
    }

    return value;
  }

  static String messageFor(String key) => _messages[key] ?? resolve(key);
}
