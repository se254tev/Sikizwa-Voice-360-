import '../../../core/errors.dart';
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
    final sanitizedIdentifier = identifier.trim();
    final sanitizedPassword = password.trim();

    _validateCredentials(
      identifier: sanitizedIdentifier,
      password: sanitizedPassword,
    );

    await api.prepareForAuth();

    final res = await api.post('/api/auth/login', data: {
      'identifier': sanitizedIdentifier,
      'password': sanitizedPassword,
      'device_id': deviceId,
      'device_type': deviceType,
    });

    final payload = _normalize(res);
    final access = payload['access'] ?? payload['token'];
    final refresh = payload['refresh'];

    if (access is! String || access.isEmpty) {
      throw ApiException(
        error: const ApiError(
          statusCode: 502,
          message: 'The authentication service returned an invalid response. Please try again.',
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
    required String role,
    required List<Map<String, String>> emergencyContacts,
    String? email,
    String? bloodGroup,
    String? allergies,
    String? medicalConditions,
    String? location,
  }) async {
    final sanitizedFullName = fullName.trim();
    final sanitizedPhone = phone.trim();
    final sanitizedPassword = password.trim();

    _validateRegistration(
      fullName: sanitizedFullName,
      phone: sanitizedPhone,
      password: sanitizedPassword,
    );

    await api.prepareForAuth();

    final res = await api.post('/api/auth/register', data: {
      'fullName': sanitizedFullName,
      'phone': sanitizedPhone,
      'password': sanitizedPassword,
      'email': email?.trim(),
      'role': role,
      'emergencyContacts': emergencyContacts,
      'bloodGroup': bloodGroup?.trim(),
      'allergies': allergies?.trim(),
      'medicalConditions': medicalConditions?.trim(),
      'location': location?.trim(),
      'device_id': deviceId,
      'device_type': deviceType,
    });

    final payload = _normalize(res);
    final access = payload['access'] ?? payload['token'];
    final refresh = payload['refresh'];

    if (access is! String || access.isEmpty) {
      throw ApiException(
        error: const ApiError(
          statusCode: 502,
          message: 'The authentication service returned an invalid response. Please try again.',
        ),
      );
    }

    return AuthSession(
      accessToken: access,
      refreshToken: refresh is String ? refresh : null,
    );
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
        error: const ApiError(
          statusCode: 502,
          message: 'The pairing service returned an invalid response. Please try again.',
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
        error: const ApiError(
          statusCode: 400,
          message: 'Please enter the pairing code, phone, and password.',
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
        error: const ApiError(
          statusCode: 502,
          message: 'The pairing service returned an invalid response. Please try again.',
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
    final trimmedIdentifier = identifier.trim();
    final trimmedPassword = password.trim();

    if (trimmedIdentifier.isEmpty || trimmedPassword.isEmpty) {
      throw ApiException(
        error: const ApiError(
          statusCode: 400,
          message: 'Please enter a phone number or username and password.',
        ),
      );
    }

    if (trimmedPassword.length < 8 || trimmedPassword.length > 128) {
      throw ApiException(
        error: const ApiError(
          statusCode: 400,
          message: 'Password must be at least 8 characters long.',
        ),
      );
    }

    if (trimmedIdentifier != identifier) {
      throw ApiException(
        error: const ApiError(
          statusCode: 400,
          message: 'Please remove extra spaces from your identifier.',
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
        error: const ApiError(
          statusCode: 400,
          message: 'Please enter your full name.',
        ),
      );
    }

    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
      throw ApiException(
        error: const ApiError(
          statusCode: 400,
          message: 'Phone number must be a valid international number.',
        ),
      );
    }

    if (password.length < 8 || password.length > 128) {
      throw ApiException(
        error: const ApiError(
          statusCode: 400,
          message: 'Password must be at least 8 characters long.',
        ),
      );
    }
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
