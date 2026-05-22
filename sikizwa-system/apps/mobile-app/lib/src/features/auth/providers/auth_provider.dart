import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../providers/app_providers.dart';
import '../repository/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final String? token;
  final String? error;
  const AuthState({this.isLoading = false, this.token, this.error});

  AuthState copyWith({bool? isLoading, String? token, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final SecureStorageService _storage;
  final AuthRepository _repo;

  AuthNotifier(this._api, this._storage): _repo = AuthRepository(_api), super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.readAuthToken();
    if (token != null && token.isNotEmpty) {
      _api.setAuthToken(token);
      state = state.copyWith(token: token);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _repo.login(email: email, password: password);
      await _storage.saveAuthToken(token);
      _api.setAuthToken(token);
      state = state.copyWith(isLoading: false, token: token);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> register({required String name, required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _repo.register(name: name, email: email, password: password);
      await _storage.saveAuthToken(token);
      _api.setAuthToken(token);
      state = state.copyWith(isLoading: false, token: token);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAuthToken();
    _api.setAuthToken(null);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.read(apiServiceProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthNotifier(api, storage);
});
