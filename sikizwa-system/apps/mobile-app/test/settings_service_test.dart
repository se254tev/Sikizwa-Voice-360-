import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sikizwa_mobile/src/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads safe defaults when preferences are empty', () async {
    final service = SettingsService();

    final settings = await service.loadSettings();

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.notificationsEnabled, isTrue);
    expect(settings.fontScale, 1.0);
    expect(settings.languageCode, 'en');
  });

  test('persists and reloads updated settings', () async {
    final service = SettingsService();

    await service.saveSettings(
      await service.loadSettings().then(
        (value) => value.copyWith(
          languageCode: 'af',
          notificationsEnabled: false,
          themeMode: ThemeMode.dark,
          fontScale: 1.15,
        ),
      ),
    );

    final reloaded = await service.loadSettings();

    expect(reloaded.languageCode, 'af');
    expect(reloaded.notificationsEnabled, isFalse);
    expect(reloaded.themeMode, ThemeMode.dark);
    expect(reloaded.fontScale, 1.15);
  });

  test('falls back safely when stored values are corrupted', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', 'invalid');
    await prefs.setString('font_scale', 'not-a-number');

    final service = SettingsService();
    final settings = await service.loadSettings();

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.fontScale, 1.0);
  });
}
