import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/config/app_config.dart';
import 'src/services/api_service.dart';
import 'src/services/auth_session_manager.dart';
import 'src/services/device_detection_service.dart';
import 'src/services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorageService();
  final api = ApiService(
    baseUrl: AppConfig.apiBaseUrl,
    storage: storage,
    enableAuth: true,
    enableCsrf: true,
  );
  final sessionManager = AuthSessionManager(api, storage);
  final deviceDetection = DeviceDetectionService(storage: storage);

  bool isAuthenticated = false;
  bool requiresPairing = false;

  try {
    final snapshot = await sessionManager.initialize();
    isAuthenticated = snapshot.isAuthenticated;
    final detection = await deviceDetection.detect();
    requiresPairing = detection.requiresPairing;
  } catch (_) {
    await sessionManager.clearSession();
    isAuthenticated = false;
    try {
      final detection = await deviceDetection.detect();
      requiresPairing = detection.requiresPairing;
    } catch (_) {
      requiresPairing = false;
    }
  }

  final initialLocation = isAuthenticated
      ? '/home'
      : requiresPairing
          ? '/pairing/generate'
          : '/login';

  runApp(
    ProviderScope(
      child: SikizwaApp(initialLocation: initialLocation),
    ),
  );
}
