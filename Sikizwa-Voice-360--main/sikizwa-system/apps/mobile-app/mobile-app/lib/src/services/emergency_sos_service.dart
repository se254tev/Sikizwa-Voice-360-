import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'api_service.dart';
import 'secure_storage_service.dart';

class EmergencySOSState {
  const EmergencySOSState({
    this.isActive = false,
    this.statusMessage = 'Ready for pendant alerts.',
    this.currentPendantId,
    this.lastBatteryLevel,
    this.lastTriggeredAt,
  });

  final bool isActive;
  final String statusMessage;
  final String? currentPendantId;
  final int? lastBatteryLevel;
  final DateTime? lastTriggeredAt;

  EmergencySOSState copyWith({
    bool? isActive,
    String? statusMessage,
    String? currentPendantId,
    int? lastBatteryLevel,
    DateTime? lastTriggeredAt,
  }) {
    return EmergencySOSState(
      isActive: isActive ?? this.isActive,
      statusMessage: statusMessage ?? this.statusMessage,
      currentPendantId: currentPendantId ?? this.currentPendantId,
      lastBatteryLevel: lastBatteryLevel ?? this.lastBatteryLevel,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
    );
  }
}

class EmergencySOSService {
  EmergencySOSService({
    required this.api,
    required this.storage,
  });

  final ApiService api;
  final SecureStorageService storage;

  final ValueNotifier<EmergencySOSState> state = ValueNotifier(
    const EmergencySOSState(),
  );

  Timer? _locationUpdateTimer;
  DateTime? _lastTriggerAt;

  Future<void> activateFromPendant({
    required String pendantId,
    required int batteryLevel,
  }) async {
    final now = DateTime.now().toUtc();

    if (_lastTriggerAt != null &&
        now.difference(_lastTriggerAt!).inSeconds < 15 &&
        state.value.isActive) {
      state.value = state.value.copyWith(
        statusMessage: 'Duplicate pendant SOS ignored for 15 seconds.',
      );
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      throw StateError('No internet connection. Please reconnect and try again.');
    }

    state.value = state.value.copyWith(
      statusMessage: 'Preparing pendant emergency alert...',
    );

    final userId = await _extractUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError('Unable to verify your account. Please sign in again.');
    }

    final position = await _getCurrentPosition();

    final payload = {
      'userId': userId,
      'pendantId': pendantId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': now.toIso8601String(),
      'batteryLevel': batteryLevel,
    };

    await api.post('/api/emergency/pendant-sos', data: payload);

    _lastTriggerAt = now;
    _startLocationUpdates(pendantId: pendantId, userId: userId);
    await WakelockPlus.enable();
    HapticFeedback.vibrate();

    state.value = state.value.copyWith(
      isActive: true,
      statusMessage: 'Pendant SOS sent. Live location updates are active.',
      currentPendantId: pendantId,
      lastBatteryLevel: batteryLevel,
      lastTriggeredAt: now,
    );
  }

  Future<void> resolveEmergency() async {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _lastTriggerAt = null;
    await WakelockPlus.disable();

    state.value = state.value.copyWith(
      isActive: false,
      statusMessage: 'Emergency mode resolved. The pendant is still connected.',
      currentPendantId: null,
      lastBatteryLevel: null,
      lastTriggeredAt: null,
    );
  }

  Future<void> _sendLocationUpdate({
    required String pendantId,
    required String userId,
  }) async {
    final position = await _getCurrentPosition();

    await api.post('/api/emergency/location-update', data: {
      'userId': userId,
      'pendantId': pendantId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void _startLocationUpdates({
    required String pendantId,
    required String userId,
  }) {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await _sendLocationUpdate(pendantId: pendantId, userId: userId);
      } catch (_) {
        // Transient update errors are ignored so the listener remains active.
      }
    });
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('GPS is unavailable. Please enable location services and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location access is required for the pendant SOS alert.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<String?> _extractUserId() async {
    final token = await storage.readAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return null;
      }

      final normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final padding = '=' * ((4 - normalized.length % 4) % 4);
      final decoded = utf8.decode(base64.decode('$normalized$padding'));
      final payload = jsonDecode(decoded);

      if (payload is Map<String, dynamic>) {
        return payload['sub']?.toString();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> registerTrustedPendant({
    required String pendantId,
    String deviceType = 'pendant',
    String? deviceName,
  }) async {
    await api.post(
      '/api/user/trusted-pendants',
      data: {
        'pendantId': pendantId,
        'deviceType': deviceType,
        if (deviceName != null && deviceName.isNotEmpty) 'deviceName': deviceName,
      },
    );
  }

  void dispose() {
    _locationUpdateTimer?.cancel();
    state.dispose();
  }
}
