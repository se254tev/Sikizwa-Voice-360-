import '../features/auth/repository/auth_repository.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';

class AuthSessionSnapshot {
  const AuthSessionSnapshot({
    required this.isAuthenticated,
    this.accessToken,
    this.refreshToken,
  });

  final bool isAuthenticated;
  final String? accessToken;
  final String? refreshToken;

  static const unauthenticated = AuthSessionSnapshot(isAuthenticated: false);
}

class AuthSessionManager {
  AuthSessionManager(this.api, this.storage);

  final ApiService api;
  final SecureStorageService storage;

  Future<AuthSessionSnapshot> initialize() async {
    await api.initialize();

    final accessToken = await storage.readAccessToken();
    final refreshToken = await storage.readRefreshToken();

    if (accessToken == null || accessToken.isEmpty) {
      return AuthSessionSnapshot.unauthenticated;
    }

    try {
      final isValid = await api.hasValidAccessToken();
      if (isValid) {
        return AuthSessionSnapshot(
          isAuthenticated: true,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      if (refreshToken == null || refreshToken.isEmpty) {
        await clearSession();
        return AuthSessionSnapshot.unauthenticated;
      }

      await api.prepareForAuth();
      await api.refreshAccessToken();
      final refreshedAccessToken = await storage.readAccessToken();

      return AuthSessionSnapshot(
        isAuthenticated: refreshedAccessToken != null && refreshedAccessToken.isNotEmpty,
        accessToken: refreshedAccessToken,
        refreshToken: refreshToken,
      );
    } catch (_) {
      await clearSession();
      return AuthSessionSnapshot.unauthenticated;
    }
  }

  Future<void> persistSession(AuthSession session) async {
    await api.setSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
  }

  Future<void> clearSession() async {
    await api.clearSession();
  }
}
