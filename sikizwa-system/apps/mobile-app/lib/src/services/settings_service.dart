import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.languageCode,
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.emailAlertsEnabled,
    required this.smsAlertsEnabled,
    required this.profileVisibility,
    required this.onlineStatusVisible,
    required this.analyticsConsent,
    required this.crashReportingConsent,
    required this.mediaVolume,
    required this.autoPlay,
    required this.backgroundPlayback,
    required this.downloadQuality,
    required this.fontScale,
    required this.highContrast,
    required this.reducedAnimations,
    required this.biometricLoginEnabled,
    required this.pinLockEnabled,
    required this.autoLogoutMinutes,
    required this.dataSaver,
    required this.autoSync,
    required this.wifiOnlyDownloads,
  });

  final ThemeMode themeMode;
  final String languageCode;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool emailAlertsEnabled;
  final bool smsAlertsEnabled;
  final bool profileVisibility;
  final bool onlineStatusVisible;
  final bool analyticsConsent;
  final bool crashReportingConsent;
  final double mediaVolume;
  final bool autoPlay;
  final bool backgroundPlayback;
  final String downloadQuality;
  final double fontScale;
  final bool highContrast;
  final bool reducedAnimations;
  final bool biometricLoginEnabled;
  final bool pinLockEnabled;
  final int autoLogoutMinutes;
  final bool dataSaver;
  final bool autoSync;
  final bool wifiOnlyDownloads;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    languageCode: 'en',
    notificationsEnabled: true,
    soundEnabled: true,
    vibrationEnabled: true,
    emailAlertsEnabled: false,
    smsAlertsEnabled: false,
    profileVisibility: true,
    onlineStatusVisible: true,
    analyticsConsent: true,
    crashReportingConsent: true,
    mediaVolume: 0.8,
    autoPlay: true,
    backgroundPlayback: false,
    downloadQuality: 'standard',
    fontScale: 1.0,
    highContrast: false,
    reducedAnimations: false,
    biometricLoginEnabled: false,
    pinLockEnabled: false,
    autoLogoutMinutes: 30,
    dataSaver: false,
    autoSync: true,
    wifiOnlyDownloads: false,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? emailAlertsEnabled,
    bool? smsAlertsEnabled,
    bool? profileVisibility,
    bool? onlineStatusVisible,
    bool? analyticsConsent,
    bool? crashReportingConsent,
    double? mediaVolume,
    bool? autoPlay,
    bool? backgroundPlayback,
    String? downloadQuality,
    double? fontScale,
    bool? highContrast,
    bool? reducedAnimations,
    bool? biometricLoginEnabled,
    bool? pinLockEnabled,
    int? autoLogoutMinutes,
    bool? dataSaver,
    bool? autoSync,
    bool? wifiOnlyDownloads,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      emailAlertsEnabled: emailAlertsEnabled ?? this.emailAlertsEnabled,
      smsAlertsEnabled: smsAlertsEnabled ?? this.smsAlertsEnabled,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      onlineStatusVisible: onlineStatusVisible ?? this.onlineStatusVisible,
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      crashReportingConsent: crashReportingConsent ?? this.crashReportingConsent,
      mediaVolume: mediaVolume ?? this.mediaVolume,
      autoPlay: autoPlay ?? this.autoPlay,
      backgroundPlayback: backgroundPlayback ?? this.backgroundPlayback,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
      reducedAnimations: reducedAnimations ?? this.reducedAnimations,
      biometricLoginEnabled: biometricLoginEnabled ?? this.biometricLoginEnabled,
      pinLockEnabled: pinLockEnabled ?? this.pinLockEnabled,
      autoLogoutMinutes: autoLogoutMinutes ?? this.autoLogoutMinutes,
      dataSaver: dataSaver ?? this.dataSaver,
      autoSync: autoSync ?? this.autoSync,
      wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode.name,
      'language_code': languageCode,
      'notifications_enabled': notificationsEnabled,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'email_alerts_enabled': emailAlertsEnabled,
      'sms_alerts_enabled': smsAlertsEnabled,
      'profile_visibility': profileVisibility,
      'online_status_visible': onlineStatusVisible,
      'analytics_consent': analyticsConsent,
      'crash_reporting_consent': crashReportingConsent,
      'media_volume': mediaVolume,
      'auto_play': autoPlay,
      'background_playback': backgroundPlayback,
      'download_quality': downloadQuality,
      'font_scale': fontScale,
      'high_contrast': highContrast,
      'reduced_animations': reducedAnimations,
      'auto_logout_minutes': autoLogoutMinutes,
      'data_saver': dataSaver,
      'auto_sync': autoSync,
      'wifi_only_downloads': wifiOnlyDownloads,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final themeMode = _themeModeFromString(json['theme_mode']?.toString());
    final languageCode = _languageCodeFromString(json['language_code']?.toString());

    return AppSettings(
      themeMode: themeMode,
      languageCode: languageCode,
      notificationsEnabled: _readBool(json['notifications_enabled'], fallback: defaults.notificationsEnabled),
      soundEnabled: _readBool(json['sound_enabled'], fallback: defaults.soundEnabled),
      vibrationEnabled: _readBool(json['vibration_enabled'], fallback: defaults.vibrationEnabled),
      emailAlertsEnabled: _readBool(json['email_alerts_enabled'], fallback: defaults.emailAlertsEnabled),
      smsAlertsEnabled: _readBool(json['sms_alerts_enabled'], fallback: defaults.smsAlertsEnabled),
      profileVisibility: _readBool(json['profile_visibility'], fallback: defaults.profileVisibility),
      onlineStatusVisible: _readBool(json['online_status_visible'], fallback: defaults.onlineStatusVisible),
      analyticsConsent: _readBool(json['analytics_consent'], fallback: defaults.analyticsConsent),
      crashReportingConsent: _readBool(json['crash_reporting_consent'], fallback: defaults.crashReportingConsent),
      mediaVolume: _readDouble(json['media_volume'], fallback: defaults.mediaVolume),
      autoPlay: _readBool(json['auto_play'], fallback: defaults.autoPlay),
      backgroundPlayback: _readBool(json['background_playback'], fallback: defaults.backgroundPlayback),
      downloadQuality: _downloadQualityFromString(json['download_quality']?.toString()),
      fontScale: _readDouble(json['font_scale'], fallback: defaults.fontScale),
      highContrast: _readBool(json['high_contrast'], fallback: defaults.highContrast),
      reducedAnimations: _readBool(json['reduced_animations'], fallback: defaults.reducedAnimations),
      biometricLoginEnabled: _readBool(json['biometric_login_enabled'], fallback: defaults.biometricLoginEnabled),
      pinLockEnabled: _readBool(json['pin_lock_enabled'], fallback: defaults.pinLockEnabled),
      autoLogoutMinutes: _readInt(json['auto_logout_minutes'], fallback: defaults.autoLogoutMinutes),
      dataSaver: _readBool(json['data_saver'], fallback: defaults.dataSaver),
      autoSync: _readBool(json['auto_sync'], fallback: defaults.autoSync),
      wifiOnlyDownloads: _readBool(json['wifi_only_downloads'], fallback: defaults.wifiOnlyDownloads),
    );
  }

  static ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _languageCodeFromString(String? value) {
    if (value == 'af' || value == 'xh') {
      return value!;
    }

    return 'en';
  }

  static String _downloadQualityFromString(String? value) {
    if (value == 'high') {
      return 'high';
    }
    return 'standard';
  }

  static bool _readBool(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value == 'true';
    }

    return fallback;
  }

  static double _readDouble(dynamic value, {required double fallback}) {
    if (value is num) {
      return value.toDouble().clamp(0.5, 1.5);
    }

    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed.clamp(0.5, 1.5);
      }
    }

    return fallback.clamp(0.5, 1.5);
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value.clamp(15, 120);
    }

    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed.clamp(15, 120);
      }
    }

    return fallback.clamp(15, 120);
  }
}

class SettingsService {
  SettingsService({SharedPreferences? preferences, SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService(),
        _sharedPreferences = preferences;

  SharedPreferences? _sharedPreferences;
  final SecureStorageService _secureStorage;

  Future<SharedPreferences> get _preferences async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await _preferences;
    final base = AppSettings.fromJson(prefs.getKeys().fold<Map<String, dynamic>>(
      <String, dynamic>{},
      (map, key) => map..[key] = prefs.get(key),
    ));

    final biometric = await _readSensitiveBool('biometric_login_enabled', fallback: base.biometricLoginEnabled);
    final pinLock = await _readSensitiveBool('pin_lock_enabled', fallback: base.pinLockEnabled);

    return base.copyWith(
      biometricLoginEnabled: biometric,
      pinLockEnabled: pinLock,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _preferences;
    final data = settings.toJson();

    await Future.wait([
      prefs.setString('theme_mode', data['theme_mode'] as String),
      prefs.setString('language_code', data['language_code'] as String),
      prefs.setBool('notifications_enabled', data['notifications_enabled'] as bool),
      prefs.setBool('sound_enabled', data['sound_enabled'] as bool),
      prefs.setBool('vibration_enabled', data['vibration_enabled'] as bool),
      prefs.setBool('email_alerts_enabled', data['email_alerts_enabled'] as bool),
      prefs.setBool('sms_alerts_enabled', data['sms_alerts_enabled'] as bool),
      prefs.setBool('profile_visibility', data['profile_visibility'] as bool),
      prefs.setBool('online_status_visible', data['online_status_visible'] as bool),
      prefs.setBool('analytics_consent', data['analytics_consent'] as bool),
      prefs.setBool('crash_reporting_consent', data['crash_reporting_consent'] as bool),
      prefs.setDouble('media_volume', data['media_volume'] as double),
      prefs.setBool('auto_play', data['auto_play'] as bool),
      prefs.setBool('background_playback', data['background_playback'] as bool),
      prefs.setString('download_quality', data['download_quality'] as String),
      prefs.setDouble('font_scale', data['font_scale'] as double),
      prefs.setBool('high_contrast', data['high_contrast'] as bool),
      prefs.setBool('reduced_animations', data['reduced_animations'] as bool),
      prefs.setInt('auto_logout_minutes', data['auto_logout_minutes'] as int),
      prefs.setBool('data_saver', data['data_saver'] as bool),
      prefs.setBool('auto_sync', data['auto_sync'] as bool),
      prefs.setBool('wifi_only_downloads', data['wifi_only_downloads'] as bool),
    ]);

    await _saveSensitiveBool('biometric_login_enabled', settings.biometricLoginEnabled);
    await _saveSensitiveBool('pin_lock_enabled', settings.pinLockEnabled);
  }

  Future<void> resetToDefaults() async {
    await saveSettings(AppSettings.defaults);
  }

  Future<bool> _readSensitiveBool(String key, {required bool fallback}) async {
    try {
      final secureValue = await _secureStorage.readBoolean(key);
      if (secureValue != null) {
        return secureValue;
      }
    } catch (_) {}

    final prefs = await _preferences;
    return prefs.getBool(key) ?? fallback;
  }

  Future<void> _saveSensitiveBool(String key, bool value) async {
    try {
      await _secureStorage.saveBoolean(key, value);
      return;
    } catch (_) {}

    final prefs = await _preferences;
    await prefs.setBool(key, value);
  }
}
