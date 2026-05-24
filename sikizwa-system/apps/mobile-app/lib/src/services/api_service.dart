import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import '../core/api_error_parser.dart';
import '../core/errors.dart';
import 'secure_storage_service.dart';

class ApiService {
  ApiService({
    required this.baseUrl,
    required SecureStorageService storage,
    this.enableAuth = true,
    this.enableCsrf = false,
  })  : _storage = storage,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
            contentType: 'application/json',
            responseType: ResponseType.json,
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _attachHeaders,
      ),
    );
  }

  final String baseUrl;
  final SecureStorageService _storage;
  final Dio _dio;
  final bool enableAuth;
  final bool enableCsrf;

  String? _accessToken;
  String? _refreshToken;
  String? _csrfToken;
  String? _csrfCookie;
  bool _ready = false;
  bool _refreshing = false;
  Completer<void>? _refreshCompleter;
  bool _csrfRefreshing = false;
  Completer<void>? _csrfCompleter;
  bool _authPreparing = false;
  Completer<void>? _authPrepareCompleter;

  Future<void> initialize() => _ensureReady();

  Future<void> setSession({required String accessToken, String? refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.saveAccessToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.saveRefreshToken(refreshToken);
    }
    _ready = true;
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _csrfToken = null;
    _csrfCookie = null;
    await _storage.deleteAllSession();
    _ready = true;
  }

  Future<bool> hasValidAccessToken() async {
    await _ensureReady();

    if (_accessToken == null || _accessToken!.isEmpty) {
      return false;
    }

    final expiry = _extractJwtExpiry(_accessToken!);
    if (expiry == null) {
      return true;
    }

    return DateTime.now().toUtc().isBefore(expiry.subtract(const Duration(seconds: 30)));
  }

  Future<void> setCsrfToken({required String token, required String cookie}) async {
    _csrfToken = token;
    _csrfCookie = cookie;
    await _storage.saveCsrfToken(token);
    await _storage.saveCsrfCookie(cookie);
  }

  Future<void> clearCsrfState() async {
    _csrfToken = null;
    _csrfCookie = null;
    await _storage.deleteCsrfToken();
    await _storage.deleteCsrfCookie();
  }

  Future<void> prepareForAuth() async {
    if (_authPreparing) {
      await _authPrepareCompleter?.future;
      return;
    }

    _authPreparing = true;
    _authPrepareCompleter = Completer<void>();

    try {
      await clearCsrfState();
      await _warmServer();
      await ensureCsrfToken();
    } on ApiException {
      rethrow;
    } on NetworkException {
      throw ApiException(
        statusCode: 503,
        message: 'Server is starting. Please wait a moment.',
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 503,
        message: 'Server is starting. Please wait a moment.',
      );
    } finally {
      _authPreparing = false;
      _authPrepareCompleter?.complete();
      _authPrepareCompleter = null;
    }
  }

  Future<void> _warmServer() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _request(
          method: 'GET',
          path: '/health',
          timeoutMs: 60000,
          skipAuth: true,
          skipCsrf: true,
        );
        return;
      } on ApiException {
        if (attempt == 2) {
          rethrow;
        }
      } on NetworkException {
        if (attempt == 2) {
          rethrow;
        }
      } catch (error) {
        if (attempt == 2) {
          rethrow;
        }
      }

      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
      }
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    int timeoutMs = 15000,
  }) async {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      timeoutMs: timeoutMs,
    );
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    int timeoutMs = 15000,
  }) async {
    return _request(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      timeoutMs: timeoutMs,
    );
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    int timeoutMs = 15000,
  }) async {
    return _request(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      timeoutMs: timeoutMs,
    );
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    int timeoutMs = 15000,
  }) async {
    return _request(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      timeoutMs: timeoutMs,
    );
  }

  Future<void> refreshAccessToken() async {
    await _ensureReady();
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      throw ApiException(
        statusCode: 401,
        message: 'Your session has expired. Please sign in again.',
      );
    }

    if (_refreshing) {
      await _refreshCompleter?.future;
      return;
    }

    _refreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      if (enableCsrf) {
        await ensureCsrfToken();
      }

      final response = await _request(
        method: 'POST',
        path: '/api/auth/refresh',
        data: {'token': _refreshToken},
        timeoutMs: 15000,
        skipAuth: true,
        isRefreshRequest: true,
      );

      final payload = response is Map<String, dynamic>
          ? response
          : (response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{});
      final access = payload['access']?.toString();

      if (access == null || access.isEmpty) {
        throw ApiException(
          statusCode: 401,
          message: 'Your session could not be refreshed.',
        );
      }

      await setSession(accessToken: access, refreshToken: _refreshToken);
    } catch (error) {
      await clearSession();
      if (error is ApiException) {
        rethrow;
      }
      rethrow;
    } finally {
      _refreshing = false;
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }

  Future<void> ensureCsrfToken() async {
    if (!enableCsrf) {
      return;
    }

    if (_csrfToken != null && _csrfToken!.isNotEmpty && _csrfCookie != null && _csrfCookie!.isNotEmpty) {
      return;
    }

    if (_csrfRefreshing) {
      await _csrfCompleter?.future;
      return;
    }

    _csrfRefreshing = true;
    _csrfCompleter = Completer<void>();

    try {
      final response = await _request(
        method: 'GET',
        path: '/api/csrf-token',
        timeoutMs: 15000,
        skipAuth: true,
        skipCsrf: true,
      );

      final payload = response is Map<String, dynamic>
          ? response
          : (response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{});
      final token = payload['csrfToken']?.toString();
      final cookie = _csrfCookie;

      if (token == null || token.isEmpty || cookie == null || cookie.isEmpty) {
        throw ApiException(
          statusCode: 500,
          message: 'Unable to initialize CSRF protection.',
        );
      }

      await setCsrfToken(token: token, cookie: cookie);
    } on DioException catch (error) {
      throw _mapDioError(error, path: '/api/csrf-token');
    } finally {
      _csrfRefreshing = false;
      _csrfCompleter?.complete();
      _csrfCompleter = null;
    }
  }

  Future<void> _ensureReady() async {
    if (_ready) {
      return;
    }

    _accessToken = await _storage.readAccessToken();
    _refreshToken = await _storage.readRefreshToken();
    _csrfToken = await _storage.readCsrfToken();
    _csrfCookie = await _storage.readCsrfCookie();
    _ready = true;
  }

  Future<dynamic> _request({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required int timeoutMs,
    bool retry = false,
    bool skipAuth = false,
    bool skipCsrf = false,
    bool isRefreshRequest = false,
    Map<String, dynamic>? extraHeaders,
  }) async {
    await _ensureReady();

    if ((method == 'POST' || method == 'PUT' || method == 'DELETE') && enableCsrf && !skipCsrf) {
      await ensureCsrfToken();
    }

    final requestHeaders = _buildHeaders(
      method: method,
      data: data,
      extraHeaders: extraHeaders,
    );
    final requestData = _prepareRequestData(data);
    final requestUrl = _resolveUrl(path);

    log(
      'API REQUEST',
      name: 'ApiService',
      error: 'method=$method url=$requestUrl headers=${_stringifyForLog(requestHeaders)} body=${_stringifyForLog(requestData)}',
    );

    try {
      final response = await _dio.request(
        path,
        data: requestData,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: requestHeaders,
          sendTimeout: Duration(milliseconds: timeoutMs),
          receiveTimeout: Duration(milliseconds: timeoutMs),
          extra: {
            'retry': retry,
            'skipAuth': skipAuth,
            'skipCsrf': skipCsrf,
          },
        ),
      );

      _captureCsrf(response);
      final decoded = _decodeJson(response.data);

      log(
        'API RESPONSE',
        name: 'ApiService',
        error: 'status=${response.statusCode} url=$requestUrl body=${_stringifyForLog(response.data)}',
      );

      return decoded;
    } on DioException catch (error) {
      log(
        'API EXCEPTION',
        name: 'ApiService',
        error: 'status=${error.response?.statusCode} url=$requestUrl message=${error.message} body=${_stringifyForLog(error.response?.data)}',
      );

      if (!retry && !isRefreshRequest && method == 'GET' && error.response?.statusCode == 401 && enableAuth && _refreshToken != null) {
        await refreshAccessToken();
        return _request(
          method: method,
          path: path,
          data: data,
          queryParameters: queryParameters,
          timeoutMs: timeoutMs,
          retry: true,
          skipAuth: skipAuth,
          skipCsrf: skipCsrf,
          isRefreshRequest: isRefreshRequest,
          extraHeaders: extraHeaders,
        );
      }

      if (!retry && !skipCsrf && method == 'GET' && error.response?.statusCode == 403 && enableCsrf) {
        await clearCsrfState();
        await ensureCsrfToken();
        return _request(
          method: method,
          path: path,
          data: data,
          queryParameters: queryParameters,
          timeoutMs: timeoutMs,
          retry: true,
          skipAuth: skipAuth,
          skipCsrf: skipCsrf,
          isRefreshRequest: isRefreshRequest,
          extraHeaders: extraHeaders,
        );
      }

      throw _mapDioError(error, path: path);
    }
  }

  Future<void> _attachHeaders(RequestOptions options, RequestInterceptorHandler handler) async {
    await _ensureReady();

    if (options.extra['skipAuth'] != true && enableAuth && _accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (options.extra['skipCsrf'] != true && enableCsrf) {
      if (_csrfToken != null && _csrfToken!.isNotEmpty) {
        options.headers['X-CSRF-Token'] = _csrfToken;
      }
      if (_csrfCookie != null && _csrfCookie!.isNotEmpty) {
        options.headers['Cookie'] = _csrfCookie;
      }
    }

    handler.next(options);
  }

  void _captureCsrf(Response response) {
    if (!enableCsrf) {
      return;
    }

    final cookie = _extractCookie(response.headers.map);
    if (cookie != null && cookie.isNotEmpty) {
      _csrfCookie = cookie;
      _storage.saveCsrfCookie(cookie);
    }
  }

  String? _extractCookie(Map<String, List<String>> headers) {
    final cookies = headers['set-cookie'];
    if (cookies == null || cookies.isEmpty) {
      return null;
    }

    for (final cookie in cookies) {
      if (cookie.contains('_csrf=')) {
        return cookie.split(';').first;
      }
    }

    return null;
  }

  Map<String, dynamic> _buildHeaders({
    required String method,
    required dynamic data,
    Map<String, dynamic>? extraHeaders,
  }) {
    final headers = <String, dynamic>{
      if (extraHeaders != null) ...extraHeaders,
    };

    if (_shouldSendJsonContentType(method, data)) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  bool _shouldSendJsonContentType(String method, dynamic data) {
    if (method == 'GET') {
      return false;
    }

    if (data is FormData || data is MultipartFile || data is File || data is Stream) {
      return false;
    }

    if (data == null) {
      return true;
    }

    return data is Map || data is List || data is String || data is num || data is bool;
  }

  dynamic _prepareRequestData(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is FormData || data is MultipartFile || data is File || data is Stream) {
      return data;
    }

    if (data is Map || data is List) {
      try {
        return jsonEncode(data);
      } on JsonUnsupportedObjectError {
        throw ApiException(
          statusCode: 400,
          message: 'The request payload is malformed. Please try again.',
        );
      } on FormatException {
        throw ApiException(
          statusCode: 400,
          message: 'The request payload is malformed. Please try again.',
        );
      }
    }

    return data;
  }

  String _resolveUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    return '${_dio.options.baseUrl}$path';
  }

  DateTime? _extractJwtExpiry(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    final normalized = parts[1]
        .replaceAll('-', '+')
        .replaceAll('_', '/');
    final padding = '=' * ((4 - normalized.length % 4) % 4);

    try {
      final decoded = utf8.decode(base64.decode('$normalized$padding'));
      final payload = jsonDecode(decoded);

      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final exp = payload['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }

      if (exp is String) {
        final parsed = int.tryParse(exp);
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsed * 1000, isUtc: true);
        }
      }
    } on Object {
      return null;
    }

    return null;
  }

  String _stringifyForLog(dynamic value) {
    if (value == null) {
      return 'null';
    }

    if (value is String) {
      return _sanitizeLogString(value);
    }

    if (value is Map || value is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(_sanitizeLogValue(value));
      } on Object {
        return value.toString();
      }
    }

    if (value is FormData) {
      return 'FormData(fields=${value.fields.length}, files=${value.files.length})';
    }

    return _sanitizeLogString(value.toString());
  }

  dynamic _sanitizeLogValue(dynamic value) {
    if (value is Map) {
      final sanitized = <dynamic, dynamic>{};
      for (final entry in value.entries) {
        sanitized[_sanitizeLogString(entry.key.toString())] = _sanitizeLogValue(entry.value);
      }
      return sanitized;
    }

    if (value is List) {
      return value.map(_sanitizeLogValue).toList();
    }

    if (value is String) {
      return _sanitizeLogString(value);
    }

    return value;
  }

  String _sanitizeLogString(String value) {
    final lowered = value.toLowerCase();
    if (lowered.contains('authorization') || lowered.contains('cookie') || lowered.contains('csrf') || lowered.contains('token') || lowered.contains('password') || lowered.contains('pairingcode') || lowered.contains('refresh') || lowered.contains('access')) {
      return '[redacted]';
    }

    if (value.length > 200) {
      return '${value.substring(0, 200)}…';
    }

    return value;
  }

  dynamic _decodeJson(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is Map || data is List) {
      return data;
    }
    if (data is String) {
      try {
        return jsonDecode(data);
      } on FormatException {
        return data;
      }
    }
    return data;
  }

  AppException _mapDioError(DioException error, {required String path}) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Connection is taking longer than expected.');
    }

    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException ||
        error.type == DioExceptionType.unknown) {
      return OfflineException('No internet connection. Please check your network and try again.');
    }

    final status = error.response?.statusCode ?? 0;
    final message = ApiErrorParser.userMessageForResponse(
      statusCode: status,
      body: error.response?.data,
      path: path,
    );

    return ApiException(
      statusCode: status,
      message: message,
      details: message,
    );
  }
}
