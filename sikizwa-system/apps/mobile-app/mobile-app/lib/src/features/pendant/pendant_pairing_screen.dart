import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../services/pendant_connection_manager.dart';
import 'widgets/ble_status_indicator.dart';

class PendantPairingScreen extends ConsumerStatefulWidget {
  const PendantPairingScreen({super.key});

  @override
  ConsumerState<PendantPairingScreen> createState() => _PendantPairingScreenState();
}

class _PendantPairingScreenState extends ConsumerState<PendantPairingScreen> {
  late final PendantConnectionManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = ref.read(pendantConnectionManagerProvider);
    unawaited(_manager.initialize());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _scan() async {
    try {
      await _manager.scanForDevices();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      await _manager.connectToDevice(device);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendant connected successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _reconnect() async {
    try {
      await _manager.reconnectIfAvailable();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconnecting to your trusted pendant.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PendantConnectionSnapshot>(
      valueListenable: _manager.state,
      builder: (context, status, _) {
        return ValueListenableBuilder<List<BluetoothDevice>>(
          valueListenable: _manager.discoveredDevices,
          builder: (context, devices, __) {
            return Scaffold(
              appBar: AppBar(title: const Text('Pendant pairing')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'BLE smart pendant',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan for nearby pendants, connect to a trusted device, and let Sikizwa reconnect automatically when it is available.',
                    ),
                    const SizedBox(height: 16),
                    BLEStatusIndicator(status: status),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: status.isScanning ? null : _scan,
                            icon: const Icon(Icons.bluetooth_searching),
                            label: const Text('Scan pendants'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: status.isReconnecting ? null : _reconnect,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reconnect'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (status.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: devices.isEmpty
                          ? Center(
                              child: Text(
                                status.isScanning
                                    ? 'Scanning for pendants...'
                                    : 'No pendants found yet. Scan to discover devices nearby.',
                              ),
                            )
                          : ListView.separated(
                              itemCount: devices.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final device = devices[index];
                                final deviceName = device.platformName.isNotEmpty
                                    ? device.platformName
                                    : 'Unnamed pendant';

                                return ListTile(
                                  leading: const Icon(Icons.watch),
                                  title: Text(deviceName),
                                  subtitle: Text(device.remoteId.str),
                                  trailing: status.isConnected && status.deviceId == device.remoteId.str
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : ElevatedButton(
                                          onPressed: () => _connect(device),
                                          child: const Text('Connect'),
                                        ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/emergency'),
                      child: const Text('Back to emergency'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
