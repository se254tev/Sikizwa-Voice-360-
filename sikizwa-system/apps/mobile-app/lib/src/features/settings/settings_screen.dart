import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(title: Text('Notifications'), subtitle: Text('Manage alerts and reminders')),
          const ListTile(title: Text('Security'), subtitle: Text('Biometric login and passcode settings')),
          const ListTile(title: Text('Support'), subtitle: Text('Contact counselors or report issues')),
          const ListTile(title: Text('Privacy'), subtitle: Text('Anonymous reporting controls')),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
