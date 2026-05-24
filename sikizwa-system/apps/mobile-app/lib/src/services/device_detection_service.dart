import 'dart:convert';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'secure_storage_service.dart';

enum AppDeviceType { phone, tablet, tv, watch }

class DeviceDetectionResult {
  const DeviceDetectionResult({
    required this.type,
    required this.deviceId,
    required this.requiresPairing,
  });

  final AppDeviceType type;
  final String deviceId;
  final bool requiresPairing;

  String get typeLabel => switch (type) {
        AppDeviceType.phone => 'phone',
        AppDeviceType.tablet => 'tablet',
        AppDeviceType.tv => 'tv',
        AppDeviceType.watch => 'watch',
      };
}

class DeviceDetectionService {
  DeviceDetectionService({
    required this.storage,
    DeviceInfoPlugin? deviceInfoPlugin,
  }) : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  final SecureStorageService storage;
  final DeviceInfoPlugin _deviceInfoPlugin;

  static AppDeviceType classifyDevice({
    required double width,
    required double height,
    required List<String> systemFeatures,
  }) {
    final isWatch = systemFeatures.any(
      (feature) => feature == 'android.hardware.type.watch',
    );
    final isTv = systemFeatures.any(
      (feature) =>
          feature == 'android.hardware.type.television' ||
          feature == 'android.software.leanback',
    );

    if (isWatch) {
      return AppDeviceType.watch;
    }

    if (isTv) {
      return AppDeviceType.tv;
    }

    final maxDimension = width > height ? width : height;
    if (maxDimension >= 900) {
      return AppDeviceType.tablet;
    }

    return AppDeviceType.phone;
  }

  Future<DeviceDetectionResult> detect() async {
    String deviceId = await storage.readDeviceId() ?? const Uuid().v4();
    if (await storage.readDeviceId() == null) {
      await storage.saveDeviceId(deviceId);
    }

    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final physicalSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio == 0 ? 1 : view.devicePixelRatio;
    final logicalSize = Size(
      physicalSize.width / devicePixelRatio,
      physicalSize.height / devicePixelRatio,
    );

    final androidInfo = await _deviceInfoPlugin.androidInfo;
    final type = classifyDevice(
      width: logicalSize.width,
      height: logicalSize.height,
      systemFeatures: androidInfo.systemFeatures,
    );

    await storage.saveDeviceType(typeLabel);

    return DeviceDetectionResult(
      type: type,
      deviceId: deviceId,
      requiresPairing: type == AppDeviceType.tv || type == AppDeviceType.watch,
    );
  }
}
