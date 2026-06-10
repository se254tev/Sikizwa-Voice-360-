import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BLEService {
  BLEService();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _packetSubscription;
  final StreamController<List<int>> _packetController = StreamController<List<int>>.broadcast();

  BluetoothDevice? get connectedDevice => _device;
  BluetoothCharacteristic? get activeCharacteristic => _characteristic;
  bool get isConnected => _device != null;

  Stream<List<int>> get packetStream => _packetController.stream;

  Future<void> initialize() async {
    await _ensurePermissions();
  }

  Future<void> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
      throw StateError('Bluetooth permissions are required to use the pendant.');
    }

    if (statuses[Permission.locationWhenInUse] != PermissionStatus.granted &&
        statuses[Permission.location] != PermissionStatus.granted) {
      throw StateError('Location permission is required to scan for the pendant.');
    }
  }

  Future<List<BluetoothDevice>> scanForDevices({Duration timeout = const Duration(seconds: 8)}) async {
    await _ensurePermissions();

    final foundDevices = <String, BluetoothDevice>{};

    final scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        foundDevices[result.device.remoteId.str] = result.device;
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await Future<void>.delayed(timeout);
      await FlutterBluePlus.stopScan();
    } finally {
      await scanSubscription.cancel();
    }

    return foundDevices.values.toList();
  }

  Future<void> connect(BluetoothDevice device) async {
    await _ensurePermissions();

    if (isConnected && _device?.remoteId.str == device.remoteId.str) {
      return;
    }

    await disconnect();

    try {
      await device.connect(timeout: const Duration(seconds: 15));
    } catch (error) {
      await device.disconnect();
      rethrow;
    }

    final services = await device.discoverServices();
    final characteristic = _findNotifyCharacteristic(services);

    if (characteristic == null) {
      await device.disconnect();
      throw StateError('The pendant is not advertising a supported SOS characteristic.');
    }

    await characteristic.setNotifyValue(true);
    _packetSubscription?.cancel();
    _packetSubscription = characteristic.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        _packetController.add(value);
      }
    });

    _device = device;
    _characteristic = characteristic;
  }

  Future<void> connectById(String deviceId) async {
    final devices = await scanForDevices(timeout: const Duration(seconds: 6));
    final target = devices.firstWhere(
      (device) => device.remoteId.str == deviceId,
      orElse: () => throw StateError('Could not reconnect to the saved pendant.'),
    );

    await connect(target);
  }

  Future<void> disconnect() async {
    await _packetSubscription?.cancel();
    _packetSubscription = null;

    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {
        // Ignore disconnect errors after the pendant has already disconnected.
      }
    }

    _device = null;
    _characteristic = null;
  }

  BluetoothCharacteristic? _findNotifyCharacteristic(List<BluetoothService> services) {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.notify || characteristic.properties.indicate) {
          return characteristic;
        }
      }
    }

    return null;
  }

  void dispose() {
    _packetSubscription?.cancel();
    _packetController.close();
  }
}
