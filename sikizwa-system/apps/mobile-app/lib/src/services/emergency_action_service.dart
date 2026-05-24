import 'dart:convert';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/auth/models/emergency_profile.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';

class EmergencyActionService {
  EmergencyActionService({
    required this.api,
    required this.storage,
  });

  final ApiService api;
  final SecureStorageService storage;

  Future<void> handleAction(String action) async {
    if (action == 'send_distress') {
      await sendDistressSignal();
      return;
    }

    if (action == 'call_contact') {
      await callPrimaryContact();
    }
  }

  Future<void> sendDistressSignal() async {
    final accessToken = await storage.readAccessToken();
    final userId = _extractUserId(accessToken);

    if (userId == null) {
      throw StateError('Unable to verify your account. Please sign in again.');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException('location');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      ),
    );

    await api.post('/api/distress-signal', data: {
      'user_id': userId,
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> callPrimaryContact() async {
    final profile = await _loadProfile();

    if (profile == null || profile.contacts.isEmpty) {
      throw StateError('No emergency contact is available.');
    }

    final contact = profile.contacts.firstWhere(
      (candidate) => candidate.type == 'personal',
      orElse: () => profile.contacts.first,
    );

    await callEmergencyNumber(contact.phone);
  }

  Future<void> callEmergencyNumber(String number) async {
    final normalized = number.trim();
    if (normalized.isEmpty) {
      throw StateError('Please provide a valid emergency number.');
    }

    final uri = Uri(scheme: 'tel', path: normalized);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw StateError('Unable to launch the phone dialer.');
    }
  }

  Future<EmergencyProfile?> _loadProfile() async {
    final json = await storage.readEmergencyProfile();
    if (json == null || json.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return EmergencyProfile.fromJson(decoded);
    } catch (error, stackTrace) {
      log('Failed to load emergency profile', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  String? _extractUserId(String? token) {
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
}
