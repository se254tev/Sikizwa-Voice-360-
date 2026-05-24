import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../services/emergency_action_service.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  bool _isSending = false;

  EmergencyActionService get _service => EmergencyActionService(
        api: ref.read(apiServiceProvider),
        storage: ref.read(secureStorageProvider),
      );

  Future<void> _sendDistressSignal() async {
    if (_isSending) {
      return;
    }

    setState(() => _isSending = true);

    try {
      await _service.sendDistressSignal();
      if (!mounted) {
        return;
      }
      _showSnackBar('Distress signal sent with your location.');
    } catch (error) {
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _callPrimaryContact() async {
    if (_isSending) {
      return;
    }

    setState(() => _isSending = true);

    try {
      await _service.callPrimaryContact();
      if (!mounted) {
        return;
      }
      _showSnackBar('Opening your primary emergency contact.');
    } catch (error) {
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Response')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Emergency support', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Trigger a safe response team or send a distress signal with your current location.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSending ? null : _sendDistressSignal,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send emergency alert'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSending ? null : _callPrimaryContact,
              child: const Text('Call primary contact'),
            ),
          ],
        ),
      ),
    );
  }
}
