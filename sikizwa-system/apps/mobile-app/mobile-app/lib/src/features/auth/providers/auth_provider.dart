import 'package:flutter_riverpod/legacy.dart';
import '../../../core/errors.dart';
import '../../../core/errors/auth_error_messages.dart';
import '../../../providers/app_providers.dart';
import '../../../services/auth_session_manager.dart';
import '../../../services/secure_storage_service.dart';
import '../repository/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final bool isReady;
  final bool isAuthenticated;
  final String? accessToken;
  final String? refreshToken;
  final String? error;
  final String? statusMessage;

  const AuthState({
    this.isLoading = false,
    this.isReady = false,
    this.isAuthenticated = false,
    this.accessToken,
    this.refreshToken,
    this.error,
    this.statusMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isReady,
    bool? isAuthenticated,
    String? accessToken,
    String? refreshToken,
    String? error,
    String? statusMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isReady: isReady ?? this.isReady,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      error: error,
      statusMessage: statusMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._sessionManager, this._storage)
      : _repo = AuthRepository(_sessionManager.api),
        super(const AuthState()) {
    _init();
  }

  final AuthSessionManager _sessionManager;
  final SecureStorageService _storage;
  final AuthRepository _repo;

  Future<void> _init() async {
    try {
      final snapshot = await _sessionManager.initialize();
      state = state.copyWith(
        isReady: true,
        isAuthenticated: snapshot.isAuthenticated,
        accessToken: snapshot.accessToken,
        refreshToken: snapshot.refreshToken,
      );
    } catch (_) {
      await _sessionManager.clearSession();
      state = state.copyWith(isReady: true);
    }
  }

  Future<String> requestPairingCode() async {
    final deviceId = await _storage.readDeviceId();
    final deviceType = await _storage.readDeviceType();

    if (deviceId == null || deviceId.isEmpty || deviceType == null || deviceType.isEmpty) {
      throw ApiException(
        error: ApiError(
          statusCode: 400,
          message: AuthErrorMessages.deviceInfoUnavailable,
        ),
      );
    }

    return _repo.requestPairingCode(deviceId: deviceId, deviceType: deviceType);
  }

  Future<void> _runAuthOperation({
    required String statusMessage,
    required Future<void> Function() action,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      statusMessage: statusMessage,
    );

    try {
      await action();
      state = state.copyWith(isLoading: false, statusMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: formatError(e),
        statusMessage: null,
      );
      rethrow;
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    await _runAuthOperation(
      statusMessage: 'Securing your sign-in…',
      action: () async {
        final deviceId = await _storage.readDeviceId();
        final deviceType = await _storage.readDeviceType();
        if (deviceId == null || deviceId.isEmpty || deviceType == null || deviceType.isEmpty) {
          throw ApiException(
            error: ApiError(
              statusCode: 400,
              message: AuthErrorMessages.deviceInfoUnavailable,
            ),
          );
        }

        final session = await _repo.login(
          identifier: identifier,
          password: password,
          deviceId: deviceId,
          deviceType: deviceType,
        );
        await _sessionManager.persistSession(session);

        state = state.copyWith(
          isAuthenticated: true,
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
      },
    );
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    await _runAuthOperation(
      statusMessage: 'Securing your sign-in…',
      action: () async {
        final deviceId = await _storage.readDeviceId();
        final deviceType = await _storage.readDeviceType();
        if (deviceId == null || deviceId.isEmpty || deviceType == null || deviceType.isEmpty) {
          throw ApiException(
            error: ApiError(
              statusCode: 400,
              message: AuthErrorMessages.deviceInfoUnavailable,
            ),
          );
        }

        final session = await _repo.register(
          fullName: fullName,
          phone: phone,
          password: password,
          deviceId: deviceId,
          deviceType: deviceType,
        );
        await _sessionManager.persistSession(session);

        state = state.copyWith(
          isAuthenticated: true,
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
      },
    );
  }

  Future<void> pairDevice({
    required String pairingCode,
    required String phone,
    required String password,
  }) async {
    await _runAuthOperation(
      statusMessage: 'Securing your sign-in…',
      action: () async {
        final deviceId = await _storage.readDeviceId();
        final deviceType = await _storage.readDeviceType();
        if (deviceId == null || deviceId.isEmpty || deviceType == null || deviceType.isEmpty) {
          throw ApiException(
            error: ApiError(
              statusCode: 400,
              message: AuthErrorMessages.deviceInfoUnavailable,
            ),
          );
        }

        final session = await _repo.pairDevice(
          pairingCode: pairingCode,
          phone: phone,
          password: password,
          deviceId: deviceId,
          deviceType: deviceType,
        );
        await _sessionManager.persistSession(session);

        state = state.copyWith(
          isAuthenticated: true,
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
      },
    );
  }

  Future<void> logout() async {
    await _sessionManager.clearSession();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.read(apiServiceProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthNotifier(AuthSessionManager(api, storage), storage);
});
