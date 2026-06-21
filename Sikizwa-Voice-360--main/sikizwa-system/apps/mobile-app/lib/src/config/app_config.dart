import '../../config/env.dart';

class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: API_BASE_URL,
  );

  static const String aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: AI_BASE_URL,
  );
}