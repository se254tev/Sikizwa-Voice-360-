import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../config/app_config.dart';
import '../../../core/errors.dart';

class AdminAuthRepository {
  AdminAuthRepository([Dio? dio]) : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  final Dio _dio;

  Future<String> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _post('/api/admin/login', {
      'identifier': identifier.trim(),
      'password': password,
    });

    final token = _normalizeToken(response);
    return token;
  }

  Future<String> signup({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String nationalId,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _post('/api/admin/signup', {
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'email': email.trim(),
      'nationalId': nationalId.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
    });

    final token = _normalizeToken(response);
    return token;
  }

  Future<Map<String, dynamic>> profile({required String token}) async {
    final response = await _dio.get(
      '/api/admin/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _normalizeMap(response.data);
  }

  Future<void> logout({required String token}) async {
    await _dio.post(
      '/api/admin/logout',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<dynamic> _post(String path, dynamic data) async {
    try {
      final response = await _dio.post(path, data: jsonEncode(data));
      return response.data;
    } on DioException catch (error) {
      throw _mapDioError(error, path: path);
    }
  }

  String _normalizeToken(dynamic payload) {
    if (payload is Map<String, dynamic> && payload['token'] is String) {
      return payload['token'] as String;
    }

    throw ApiException(
      statusCode: 502,
      message: 'Authentication service returned an invalid response.',
    );
  }

  Map<String, dynamic> _normalizeMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return <String, dynamic>{};
  }
}
