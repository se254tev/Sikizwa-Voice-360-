import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sikizwa Home')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Voice Reporting', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choose the support flow that fits your moment.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/reports'),
              child: const Text('Create a new report'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/emergency'),
              child: const Text('Emergency response'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/wellness'),
              child: const Text('Emotional wellness'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.go('/ai-chat'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Talk to Sikizwa AI'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/settings'),
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
