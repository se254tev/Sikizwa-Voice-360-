import 'package:flutter/services.dart';

class EmergencyForegroundServiceController {
  EmergencyForegroundServiceController(this.actionHandler);

  final Future<void> Function(String action) actionHandler;

  static const MethodChannel _channel = MethodChannel('sikizwa/emergency');

  Future<void> initialize() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'emergencyAction') {
        final action = call.arguments['action']?.toString();
        if (action != null && action.isNotEmpty) {
          await actionHandler(action);
        }
      }
    });
  }

  Future<void> startEmergency() async {
    await _channel.invokeMethod<void>('startEmergency');
  }

  Future<void> stopEmergency() async {
    await _channel.invokeMethod<void>('stopEmergency');
  }
}
