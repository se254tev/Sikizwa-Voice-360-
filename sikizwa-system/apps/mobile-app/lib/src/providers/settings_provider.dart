import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._service) : super(AppSettings.defaults) {
    _load();
  }

  final SettingsService _service;

  Future<void> _load() async {
    final loaded = await _service.loadSettings();
    state = loaded;
  }

  Future<void> updateSettings(AppSettings Function(AppSettings current) updater) async {
    final current = state;
    final next = updater(current);
    state = next;

    try {
      await _service.saveSettings(next);
    } catch (_) {
      state = current;
      rethrow;
    }
  }

  Future<void> reset() async {
    final current = state;
    state = AppSettings.defaults;

    try {
      await _service.resetToDefaults();
    } catch (_) {
      state = current;
      rethrow;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(SettingsService()),
);
