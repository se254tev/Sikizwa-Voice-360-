import 'package:flutter/material.dart';

import '../../../services/emergency_sos_service.dart';

class EmergencyAlertOverlay extends StatelessWidget {
  const EmergencyAlertOverlay({
    super.key,
    required this.state,
    required this.onResolve,
  });

  final EmergencySOSState state;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Pendant SOS active',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(state.statusMessage),
                    if (state.currentPendantId != null) ...[
                      const SizedBox(height: 8),
                      Text('Pendant: ${state.currentPendantId}'),
                    ],
                    if (state.lastBatteryLevel != null) ...[
                      const SizedBox(height: 8),
                      Text('Battery: ${state.lastBatteryLevel}%'),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onResolve,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Resolve emergency'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
