import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';
import '../../../core/errors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/secure_storage_service.dart';
import '../repository/admin_auth_repository.dart';

class AdminAuthState {
  final bool isLoading;
  final bool isReady;
  final bool isAuthenticated;
  final String? token;
  final String? error;
  final Map<String, dynamic>? admin;

  const AdminAuthState({
    this.isLoading = false,
    this.isReady = false,
    this.isAuthenticated = false,
    this.token,
    this.error,
    this.admin,
  });

  AdminAuthState copyWith({
    bool? isLoading,
    bool? isReady,
    bool? isAuthenticated,
    String? token,
    String? error,
    Map<String, dynamic>? admin,
  }) {
    return AdminAuthState(
      isLoading: isLoading ?? this.isLoading,
      isReady: isReady ?? this.isReady,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      error: error,
      admin: admin ?? this.admin,
    );
  }
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  AdminAuthNotifier(this._storage)
      : _repo = AdminAuthRepository(),
        super(const AdminAuthState()) {
    _init();
  }

  final SecureStorageService _storage;
  final AdminAuthRepository _repo;

  Future<void> _init() async {
    try {
      final token = await _storage.readAdminAccessToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isReady: true);
        return;
      }

      final response = await _repo.profile(token: token);
      final admin = response['admin'] is Map ? Map<String, dynamic>.from(response['admin']) : null;
      state = state.copyWith(
        isReady: true,
        isAuthenticated: true,
        token: token,
        admin: admin,
      );
    } catch (_) {
      await _storage.deleteAdminAccessToken();
      state = state.copyWith(isReady: true, isAuthenticated: false, token: null, admin: null);
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _repo.login(identifier: identifier, password: password);
      await _persist(token);
      final profile = await _repo.profile(token: token);
      final admin = profile['admin'] is Map ? Map<String, dynamic>.from(profile['admin']) : null;
      if (admin != null) {
        await _storage.saveAdminProfile(jsonEncode(admin));
      }
      state = state.copyWith(isLoading: false, isAuthenticated: true, token: token, admin: admin);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: formatError(error));
      rethrow;
    }
  }

  Future<void> signup({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String nationalId,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _repo.signup(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        nationalId: nationalId,
        password: password,
        confirmPassword: confirmPassword,
      );
      await _persist(token);
      final profile = await _repo.profile(token: token);
      final admin = profile['admin'] is Map ? Map<String, dynamic>.from(profile['admin']) : null;
      if (admin != null) {
        await _storage.saveAdminProfile(jsonEncode(admin));
      }
      state = state.copyWith(isLoading: false, isAuthenticated: true, token: token, admin: admin);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: formatError(error));
      rethrow;
    }
  }

  Future<void> logout() async {
    if (state.token != null && state.token!.isNotEmpty) {
      try {
        await _repo.logout(token: state.token!);
      } catch (_) {
        // ignore logout errors, always clear local session
      }
    }
    await _storage.deleteAdminAccessToken();
    await _storage.deleteAdminProfile();
    state = const AdminAuthState(isReady: true);
  }

  Future<void> _persist(String token) async {
    await _storage.saveAdminAccessToken(token);
  }
}

final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  final storage = ref.read(secureStorageProvider);
  return AdminAuthNotifier(storage);
});
