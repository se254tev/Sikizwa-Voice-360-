import 'dart:convert';

import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../core/errors.dart';

class ApiService {
  final Dio _dio;
  String? _authToken;

  ApiService({Dio? dio, String? authToken}) : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)) {
    _authToken = authToken;
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      if (_authToken != null && _authToken!.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $_authToken';
      }
      return handler.next(options);
    }, onError: (e, handler) {
      return handler.next(e);
    }));
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, int timeoutMs = 15000}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters).timeout(Duration(milliseconds: timeoutMs));
      return _processResponse(response);
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, int timeoutMs = 15000}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters).timeout(Duration(milliseconds: timeoutMs));
      return _processResponse(response);
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, int timeoutMs = 15000}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters).timeout(Duration(milliseconds: timeoutMs));
      return _processResponse(response);
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, int timeoutMs = 15000}) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters).timeout(Duration(milliseconds: timeoutMs));
      return _processResponse(response);
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  dynamic _processResponse(Response response) {
    final status = response.statusCode ?? 0;
    final data = response.data;
    if (status >= 200 && status < 300) {
      return data;
    } else {
      throw ApiException(statusCode: status, message: data is Map && data['message'] != null ? data['message'].toString() : 'Unknown error');
    }
  }

  Exception _mapDioError(DioError e) {
    if (e.type == DioErrorType.connectTimeout || e.type == DioErrorType.sendTimeout || e.type == DioErrorType.receiveTimeout) {
      return NetworkException('Request timed out');
    }

    if (e.type == DioErrorType.response) {
      final status = e.response?.statusCode ?? 0;
      final data = e.response?.data;
      final message = data is Map && data['message'] != null ? data['message'].toString() : e.message;
      return ApiException(statusCode: status, message: message.toString());
    }

    return NetworkException(e.message ?? 'Network error');
  }
}
