import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble_service.dart';
import 'emergency_sos_service.dart';

class PendantConnectionSnapshot {
  const PendantConnectionSnapshot({
    required this.isConnected,
    required this.isScanning,
    required this.isReconnecting,
    required this.statusMessage,
    this.deviceName,
    this.deviceId,
    this.errorMessage,
  });

  final bool isConnected;
  final bool isScanning;
  final bool isReconnecting;
  final String statusMessage;
  final String? deviceName;
  final String? deviceId;
  final String? errorMessage;

  PendantConnectionSnapshot copyWith({
    bool? isConnected,
    bool? isScanning,
    bool? isReconnecting,
    String? statusMessage,
    String? deviceName,
    String? deviceId,
    String? errorMessage,
  }) {
    return PendantConnectionSnapshot(
      isConnected: isConnected ?? this.isConnected,
      isScanning: isScanning ?? this.isScanning,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      statusMessage: statusMessage ?? this.statusMessage,
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      errorMessage: errorMessage,
    );
  }

  static const disconnected = PendantConnectionSnapshot(
    isConnected: false,
    isScanning: false,
    isReconnecting: false,
    statusMessage: 'No pendant connected.',
  );
}

class PendantConnectionManager {
  PendantConnectionManager({
    required this.bleService,
    required this.sosService,
  });

  final BLEService bleService;
  final EmergencySOSService sosService;

  final ValueNotifier<PendantConnectionSnapshot> state = ValueNotifier(
    PendantConnectionSnapshot.disconnected,
  );

  final ValueNotifier<List<BluetoothDevice>> discoveredDevices = ValueNotifier(const []);

  static const String _trustedPendantKey = 'trusted_pendant_id';

  StreamSubscription<List<int>>? _packetSubscription;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await bleService.initialize();
    await reconnectIfAvailable();
  }

  Future<void> scanForDevices() async {
    state.value = state.value.copyWith(
      isScanning: true,
      statusMessage: 'Scanning for nearby pendants...',
      errorMessage: null,
    );

    try {
      final devices = await bleService.scanForDevices();
      discoveredDevices.value = devices;
      state.value = state.value.copyWith(
        isScanning: false,
        statusMessage: 'Found ${devices.length} nearby pendant(s).',
        errorMessage: null,
      );
    } catch (error) {
      state.value = state.value.copyWith(
        isScanning: false,
        statusMessage: 'Unable to scan for pendants.',
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    state.value = state.value.copyWith(
      isScanning: false,
      isReconnecting: false,
      statusMessage: 'Connecting to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}...',
      errorMessage: null,
    );

    try {
      await bleService.connect(device);
      await _saveTrustedPendant(device.remoteId.str);
      unawaited(_syncTrustedPendant(device));
      await _startPacketListener(device.remoteId.str);

      state.value = state.value.copyWith(
        isConnected: true,
        statusMessage: 'Connected to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}.',
        deviceName: device.platformName.isNotEmpty ? device.platformName : device.remoteId.str,
        deviceId: device.remoteId.str,
        errorMessage: null,
      );
    } catch (error) {
      state.value = state.value.copyWith(
        isConnected: false,
        statusMessage: 'Failed to connect to the pendant.',
        deviceName: null,
        deviceId: null,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> reconnectIfAvailable() async {
    final savedId = _prefs?.getString(_trustedPendantKey);
    if (savedId == null || savedId.isEmpty) {
      return;
    }

    state.value = state.value.copyWith(
      isReconnecting: true,
      statusMessage: 'Reconnecting to pendant...',
      errorMessage: null,
    );

    try {
      final devices = await bleService.scanForDevices(timeout: const Duration(seconds: 6));
      final target = devices.firstWhere(
        (device) => device.remoteId.str == savedId,
        orElse: () => throw StateError('Saved pendant is not nearby.'),
      );

      await connectToDevice(target);
      state.value = state.value.copyWith(isReconnecting: false);
    } catch (error) {
      state.value = state.value.copyWith(
        isReconnecting: false,
        statusMessage: 'Reconnecting to pendant failed.',
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _packetSubscription?.cancel();
    _packetSubscription = null;
    await bleService.disconnect();

    state.value = const PendantConnectionSnapshot(
      isConnected: false,
      isScanning: false,
      isReconnecting: false,
      statusMessage: 'Pendant disconnected.',
    );
  }

  Future<void> _saveTrustedPendant(String deviceId) async {
    await _prefs?.setString(_trustedPendantKey, deviceId);
  }

  Future<void> _syncTrustedPendant(BluetoothDevice device) async {
    try {
      await sosService.registerTrustedPendant(
        pendantId: device.remoteId.str,
        deviceName: device.platformName.isNotEmpty ? device.platformName : null,
      );
    } catch (error) {
      debugPrint('Unable to sync trusted pendant to server: $error');
    }
  }

  Future<void> _startPacketListener(String deviceId) async {
    await _packetSubscription?.cancel();

    _packetSubscription = bleService.packetStream.listen((packet) async {
      final parsed = _parseSosPacket(packet);
      if (parsed == null) {
        return;
      }

      final batteryLevel = parsed['batteryLevel'] is int
          ? parsed['batteryLevel'] as int
          : parsed['batteryLevel'] is double
              ? (parsed['batteryLevel'] as double).round()
              : 100;

      await sosService.activateFromPendant(
        pendantId: deviceId,
        batteryLevel: batteryLevel,
      );
    });
  }

  Map<String, dynamic>? _parseSosPacket(List<int> packet) {
    final decoded = String.fromCharCodes(packet).trim();
    if (decoded.isEmpty) {
      return null;
    }

    final lower = decoded.toLowerCase();
    if (!lower.contains('sos') && !lower.contains('panic') && !lower.contains('emergency')) {
      return null;
    }

    try {
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        return json;
      }
    } catch (_) {
      return {'batteryLevel': 100};
    }

    return {'batteryLevel': 100};
  }

  void dispose() {
    _packetSubscription?.cancel();
    state.dispose();
    discoveredDevices.dispose();
  }
}
