import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/ble_service.dart';
import '../services/connection_check_service.dart';
import '../services/emergency_sos_service.dart';
import '../services/pendant_connection_manager.dart';
import '../services/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiService(
    baseUrl: AppConfig.apiBaseUrl,
    storage: storage,
    enableAuth: true,
    enableCsrf: false,
  );
});

final aiApiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiService(
    baseUrl: AppConfig.aiBaseUrl,
    storage: storage,
    enableAuth: true,
    enableCsrf: false,
  );
});

final connectionCheckServiceProvider = Provider<ConnectionCheckService>((ref) {
  final backend = ref.read(apiServiceProvider);
  final ai = ref.read(aiApiServiceProvider);
  return ConnectionCheckService(backendApi: backend, aiApi: ai);
});

final connectionStatusProvider = StateProvider<Map<String, bool>>((ref) => {
  'backend': false,
  'ai_service': false,
});

final bleServiceProvider = Provider<BLEService>((ref) => BLEService());

final emergencySOSServiceProvider = Provider<EmergencySOSService>((ref) {
  final api = ref.read(apiServiceProvider);
  final storage = ref.read(secureStorageProvider);
  return EmergencySOSService(api: api, storage: storage);
});

final pendantConnectionManagerProvider = Provider<PendantConnectionManager>((ref) {
  final bleService = ref.read(bleServiceProvider);
  final sosService = ref.read(emergencySOSServiceProvider);
  return PendantConnectionManager(
    bleService: bleService,
    sosService: sosService,
  );
});
