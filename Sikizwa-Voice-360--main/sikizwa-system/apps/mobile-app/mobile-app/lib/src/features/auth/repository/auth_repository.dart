import '../../../core/errors.dart';
import '../../../core/errors/auth_error_messages.dart';
import '../../../services/api_service.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
}

class AuthRepository {
  const AuthRepository(this.api);

  final ApiService api;

  Future<AuthSession> login({
    required String identifier,
    required String password,
    required String deviceId,
    required String deviceType,
  }) async {
    final normalizedIdentifier = _normalizePhone(identifier);
    final sanitizedPassword = password.trim();

    _validateCredentials(
      identifier: normalizedIdentifier,
      password: sanitizedPassword,
    );

    await api.prepareForAuth();

    final res = await api.post('/api/auth/login', data: {
      'identifier': normalizedIdentifier,
      'password': sanitizedPassword,
      'device_id': deviceId,
      'device_type': deviceType,
    });

    final payload = _normalize(res);
    final access = payload['access'] ?? payload['token'];
    final refresh = payload['refresh'];

    if (access is! String || access.isEmpty) {
      throw ApiException(
        error: ApiError(
          statusCode: 502,
          message: AuthErrorMessages.malformedRequest,
        ),
      );
    }

    return AuthSession(
      accessToken: access,
      refreshToken: refresh is String ? refresh : null,
    );
  }

  Future<AuthSession> register({
    required String fullName,
    required String phone,
    required String password,
    required String deviceId,
    required String deviceType,
  }) async {
    final sanitizedFullName = fullName.trim();
    final normalizedPhone = _normalizePhone(phone);
    final sanitizedPassword = password.trim();

    _validateRegistration(
      fullName: sanitizedFullName,
      phone: normalizedPhone,
      password: sanitizedPassword,
    );

    await api.prepareForAuth();

    final res = await api.post('/api/auth/register', data: {
      'fullName': sanitizedFullName,
      'phone': normalizedPhone,
      'password': sanitizedPassword,
      'device_id': deviceId,
      'device_type': deviceType,
    });

    final payload = _normalize(res);
    final access = payload['access'] ?? payload['token'];
    final refresh = payload['refresh'];

    if (access is! String || access.isEmpty) {
      throw ApiException(
        error: ApiError(
          statusCode: 502,
          message: AuthErrorMessages.malformedRequest,
        ),
      );
    }

    return AuthSession(
      accessToken: access,
      refreshToken: refresh is String ? refresh : null,
    );
  }

  Future<String> requestPasswordReset({
    required String phone,
  }) async {
    final normalizedPhone = _normalizePhone(phone);

    await api.prepareForAuth();

    final res = await api.post('/api/auth/forgot-password', data: {
      'phone': normalizedPhone,
    });

    final payload = _normalize(res);
    final message = payload['message']?.toString();

    if (message?.isNotEmpty == true) {
      return message!;
    }

    return AuthErrorMessages.messageFor(AuthErrorMessages.resetCodeSent);
  }

  Future<String> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final normalizedOtp = otp.trim();

    if (normalizedOtp.isEmpty || !RegExp(r'^\d{6}$').hasMatch(normalizedOtp)) {
      throw ApiException(
        error: ApiError(
          statusCode: 400,
          message: AuthErrorMessages.messageFor(AuthErrorMessages.otpRequired),
        ),
      );
    }

    await api.prepareForAuth();

    final res = await api.post('/api/auth/verify-otp', data: {
      'phone': normalizedPhone,
      'otp': normalizedOtp,
    });

    final payload = _normalize(res);
    final message = payload['message']?.toString();

    if (message?.isNotEmpty == true) {
      return message!;
    }

    return AuthErrorMessages.messageFor(AuthErrorMessages.otpVerified);
  }

  Future<String> resetPassword({
    required String phone,
    required String otp,
    required String password,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final normalizedOtp = otp.trim();
    final normalizedPassword = password.trim();

    _validatePasswordStrength(normalizedPassword);

    if (normalizedOtp.isEmpty || !RegExp(r'^\d{6}$').hasMatch(normalizedOtp)) {
      throw ApiException(
        error: ApiError(
          statusCode: 400,
          message: AuthErrorMessages.messageFor(AuthErrorMessages.otpRequired),
        ),
      );
    }

    await api.prepareForAuth();

    final res = await api.post('/api/auth/reset-password', data: {
      'phone': normalizedPhone,
      'otp': normalizedOtp,
      'password': normalizedPassword,
    });

    final payload = _normalize(res);
    final message = payload['message']?.toString();

    if (message?.isNotEmpty == true) {
      return message!;
    }

    return AuthErrorMessages.messageFor(AuthErrorMessages.passwordUpdated);
  }

  Future<String> requestPairingCode({
    required String deviceId,
    required String deviceType,
  }) async {
    final res = await api.post('/api/device/issue', data: {
      'device_id': deviceId,
      'device_type': deviceType,
    });

    final payload = _normalize(res);
    final code = payload['pairingCode'];

    if (code is! String || code.isEmpty) {
      throw ApiException(
        error: ApiError(
          statusCode: 502,
          message: AuthErrorMessages.malformedRequest,
        ),
      );
    }

    return code;
  }

  Future<AuthSession> pairDevice({
    required String pairingCode,
    required String phone,
    required String password,
    required String deviceId,
    required String deviceType,
  }) async {
    final sanitizedPhone = phone.trim();
    final sanitizedPassword = password.trim();
    final sanitizedPairingCode = pairingCode.trim();

    if (sanitizedPhone.isEmpty || sanitizedPassword.isEmpty || sanitizedPairingCode.isEmpty) {
      throw ApiException(
        error: ApiError(
          statusCode: 400,
          message: AuthErrorMessages.messageFor(AuthErrorMessages.pairingRequired),
        ),
      );
    }

    await api.prepareForAuth();

    final res = await api.post('/api/device/link', data: {
      'phone': sanitizedPhone,
      'password': sanitizedPassword,
      'device_id': deviceId,
      'device_type': deviceType,
      'pairing_code': sanitizedPairingCode,
    });

    final payload = _normalize(res);
    final access = payload['access'] ?? payload['token'];
    final refresh = payload['refresh'];

    if (access is! String || access.isEmpty) {
      throw ApiException(
        error: ApiError(
          statusCode: 502,
          message: AuthErrorMessages.malformedRequest,
        ),
      );
    }

    return AuthSession(
      accessToken: access,
      refreshToken: refresh is String ? refresh : null,
    );
  }

  void _validateCredentials({
    required String identifier,
    required String password,
  }) {
    if (identifier.isEmpty || password.isEmpty) {
      throw ApiException(
        error: ApiError(
          statusCode: 400,
          message: AuthErrorMessages.messageFor(AuthErrorMessages.credentialsRequired),
        ),
      );
    }

    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(identifier)) {
      throw ApiException(
        error: ApiError(
          statusCode: 400,
          message: AuthErrorMessages.messageFor(AuthErrorMessages.invalidPhone),
        ),
      );
    }

    if (password.length < 8 || password.length > 128) {
      throw ApiException(
        error: ApiError(
          statusCode: 400,
          message: AuthErrorMessages.messageFor(AuthErrorMessages.passwordTooShort),
        ),
      );
    }
  }

  void _validatePasswordStrength(String password) {
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(password)) {
      throw ApiException(
        error: ApiError(
          statusCode: 400,
          message: AuthErrorMessages.messageFor(AuthErrorMessages.weakPassword),
        ),
      );
    }
  }

  void _validateRegistration({
    required String fullName,
    required String phone,
    required String password,
  }) {
    if (fullName.isEmpty) {
      throw ApiException(
        error: ApiError(
          statusCode: 400,
          message: AuthErrorMessages.messageFor(AuthErrorMessages.fullNameRequired),
        ),
      );
    }

    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
      throw ApiException(
        error: ApiError(
          statusCode: 400,
          message: AuthErrorMessages.messageFor(AuthErrorMessages.invalidPhone),
        ),
      );
    }

    _validatePasswordStrength(password);
  }

  String _normalizePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final normalized = trimmed.replaceAll(RegExp(r'[\s\-()]'), '');
    return normalized;
  }

  Map<String, dynamic> _normalize(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    return <String, dynamic>{};
  }
}
