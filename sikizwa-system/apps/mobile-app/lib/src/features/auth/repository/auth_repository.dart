import '../../../services/api_service.dart';

class AuthRepository {
  final ApiService api;
  AuthRepository(this.api);

  /// Expected response: { "token": "<jwt>", ... }
  Future<String> login({required String email, required String password}) async {
    final res = await api.post('/auth/login', data: {'email': email, 'password': password});
    if (res is Map && res['token'] != null) {
      return res['token'] as String;
    }
    throw Exception('Invalid login response');
  }

  Future<String> register({required String name, required String email, required String password}) async {
    final res = await api.post('/auth/register', data: {'name': name, 'email': email, 'password': password});
    if (res is Map && res['token'] != null) {
      return res['token'] as String;
    }
    throw Exception('Invalid register response');
  }
}
