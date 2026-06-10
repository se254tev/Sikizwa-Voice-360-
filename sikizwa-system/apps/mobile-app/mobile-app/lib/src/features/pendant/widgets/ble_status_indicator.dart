import 'package:flutter/material.dart';

import '../../../services/pendant_connection_manager.dart';

class BLEStatusIndicator extends StatelessWidget {
  const BLEStatusIndicator({super.key, required this.status});

  final PendantConnectionSnapshot status;

  @override
  Widget build(BuildContext context) {
    final isGood = status.isConnected;
    final color = isGood ? Colors.green : status.isReconnecting ? Colors.orange : Colors.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth_audio, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.statusMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (status.deviceName != null)
                  Text(
                    status.deviceName!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
