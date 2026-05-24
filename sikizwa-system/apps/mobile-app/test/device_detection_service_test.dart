import 'package:flutter_test/flutter_test.dart';
import 'package:sikizwa_mobile/src/services/device_detection_service.dart';

void main() {
  test('classifies TV devices using platform features', () {
    final result = DeviceDetectionService.classifyDevice(
      width: 1920,
      height: 1080,
      systemFeatures: ['android.hardware.type.television'],
    );

    expect(result, AppDeviceType.tv);
  });

  test('classifies tablets using large screens', () {
    final result = DeviceDetectionService.classifyDevice(
      width: 1200,
      height: 800,
      systemFeatures: [],
    );

    expect(result, AppDeviceType.tablet);
  });

  test('classifies watches using watch feature', () {
    final result = DeviceDetectionService.classifyDevice(
      width: 320,
      height: 320,
      systemFeatures: ['android.hardware.type.watch'],
    );

    expect(result, AppDeviceType.watch);
  });
}
