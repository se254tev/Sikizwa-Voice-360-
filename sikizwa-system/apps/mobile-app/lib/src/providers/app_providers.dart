import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiService(
    baseUrl: AppConfig.apiBaseUrl,
    storage: storage,
    enableAuth: true,
    enableCsrf: true,
  );
});

final aiApiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiService(
    baseUrl: AppConfig.aiBaseUrl,
    storage: storage,
    enableAuth: false,
    enableCsrf: false,
  );
});
