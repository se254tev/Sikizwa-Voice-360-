import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/admin_auth_provider.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (context.mounted) {
                context.go('/admin/login');
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: !auth.isReady
            ? const Center(child: CircularProgressIndicator())
            : auth.isAuthenticated
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back, admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Your admin session is active. Use the web dashboard for management features.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      const SizedBox(height: 24),
                      if (auth.admin != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Admin profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                                const SizedBox(height: 12),
                                Text('Name: ${auth.admin?['fullName'] ?? 'N/A'}'),
                                Text('Email: ${auth.admin?['email'] ?? 'N/A'}'),
                                Text('Phone: ${auth.admin?['phoneNumber'] ?? auth.admin?['phone'] ?? 'N/A'}'),
                                Text('National ID: ${auth.admin?['nationalId'] ?? 'N/A'}'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(child: Text('You are not authorized to view this page.')),
      ),
    );
  }
}
