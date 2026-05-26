import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors.dart';
import '../../providers/app_providers.dart';
import '../../services/emergency_action_service.dart';
import '../../services/emergency_sos_service.dart';
import '../../services/pendant_connection_manager.dart';
import '../pendant/widgets/ble_status_indicator.dart';
import '../pendant/widgets/emergency_alert_overlay.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> with SingleTickerProviderStateMixin {
  bool _isSending = false;
  late final EmergencySOSService _sosService;
  late final PendantConnectionManager _pendantManager;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  EmergencyActionService get _service => EmergencyActionService(
        api: ref.read(apiServiceProvider),
        storage: ref.read(secureStorageProvider),
      );

  @override
  void initState() {
    super.initState();
    _sosService = ref.read(emergencySOSServiceProvider);
    _pendantManager = ref.read(pendantConnectionManagerProvider);
    _pendantManager.initialize();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
      _showSnackBar(formatError(error));
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
      _showSnackBar(_formatPrimaryContactError(error));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _formatPrimaryContactError(Object error) {
    if (error is StateError && error.message == 'No emergency contact is available.') {
      return 'No contact found';
    }

    return formatError(error);
  }

  Future<void> _callEmergencyNumber(String number, String label) async {
    if (_isSending) {
      return;
    }

    setState(() => _isSending = true);

    try {
      await _service.callEmergencyNumber(number);
      if (!mounted) {
        return;
      }
      _showSnackBar('Opening $label on your phone.');
    } catch (error) {
      _showSnackBar(formatError(error));
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
    return ValueListenableBuilder<PendantConnectionSnapshot>(
      valueListenable: _pendantManager.state,
      builder: (context, pendantStatus, _) {
        return ValueListenableBuilder<EmergencySOSState>(
          valueListenable: _sosService.state,
          builder: (context, sosState, _) {
            return Stack(
              children: [
                Scaffold(
                  appBar: AppBar(title: const Text('Alert')),
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Alert support',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Send an alert, call your saved contact, or reach the national emergency numbers in Kenya.',
                        ),
                        const SizedBox(height: 16),
                        BLEStatusIndicator(status: pendantStatus),
                        const SizedBox(height: 24),
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.22),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isSending ? null : _sendDistressSignal,
                              child: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Send alert'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isSending ? null : _callPrimaryContact,
                          child: const Text('Call primary contact'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isSending ? null : () => _callEmergencyNumber('999', '999'),
                          child: const Text('Call 999'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isSending ? null : () => _callEmergencyNumber('112', '112'),
                          child: const Text('Call 112'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.go('/pendant-pairing'),
                          child: const Text('Open BLE pendant pairing'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (sosState.isActive)
                  EmergencyAlertOverlay(
                    state: sosState,
                    onResolve: () async {
                      await _sosService.resolveEmergency();
                      if (!mounted) {
                        return;
                      }
                      _showSnackBar('Emergency mode resolved.');
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
