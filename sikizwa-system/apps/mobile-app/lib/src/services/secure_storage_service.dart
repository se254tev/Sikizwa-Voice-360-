import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyCsrfToken = 'csrf_token';
  static const _keyCsrfCookie = 'csrf_cookie';
  static const _keyDeviceId = 'device_id';
  static const _keyDeviceType = 'device_type';
  static const _keyEmergencyProfile = 'emergency_profile';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<void> saveCsrfToken(String token) async {
    await _storage.write(key: _keyCsrfToken, value: token);
  }

  Future<void> saveCsrfCookie(String cookie) async {
    await _storage.write(key: _keyCsrfCookie, value: cookie);
  }

  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _keyDeviceId, value: deviceId);
  }

  Future<void> saveDeviceType(String deviceType) async {
    await _storage.write(key: _keyDeviceType, value: deviceType);
  }

  Future<void> saveEmergencyProfile(String payload) async {
    await _storage.write(key: _keyEmergencyProfile, value: payload);
  }

  Future<String?> readAccessToken() async => _storage.read(key: _keyAccessToken);

  Future<String?> readRefreshToken() async => _storage.read(key: _keyRefreshToken);

  Future<String?> readCsrfToken() async => _storage.read(key: _keyCsrfToken);

  Future<String?> readCsrfCookie() async => _storage.read(key: _keyCsrfCookie);

  Future<String?> readDeviceId() async => _storage.read(key: _keyDeviceId);

  Future<String?> readDeviceType() async => _storage.read(key: _keyDeviceType);

  Future<String?> readEmergencyProfile() async => _storage.read(key: _keyEmergencyProfile);

  Future<void> deleteAccessToken() async => _storage.delete(key: _keyAccessToken);

  Future<void> deleteRefreshToken() async => _storage.delete(key: _keyRefreshToken);

  Future<void> deleteCsrfToken() async => _storage.delete(key: _keyCsrfToken);

  Future<void> deleteCsrfCookie() async => _storage.delete(key: _keyCsrfCookie);

  Future<void> deleteDeviceId() async => _storage.delete(key: _keyDeviceId);

  Future<void> deleteDeviceType() async => _storage.delete(key: _keyDeviceType);

  Future<void> deleteEmergencyProfile() async => _storage.delete(key: _keyEmergencyProfile);

  Future<void> saveAuthToken(String token) async => saveAccessToken(token);

  Future<String?> readAuthToken() async => readAccessToken();

  Future<void> deleteAuthToken() async => deleteAccessToken();

  Future<void> deleteAllSession() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
      deleteCsrfToken(),
      deleteCsrfCookie(),
      deleteDeviceId(),
      deleteDeviceType(),
      deleteEmergencyProfile(),
    ]);
  }

  Future<void> saveBoolean(String key, bool value) async {
    await _storage.write(key: key, value: value ? 'true' : 'false');
  }

  Future<bool?> readBoolean(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) {
      return null;
    }

    return value == 'true';
  }
}
