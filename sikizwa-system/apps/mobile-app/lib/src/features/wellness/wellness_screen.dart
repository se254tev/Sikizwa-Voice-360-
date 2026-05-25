import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wellness')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Wellness tools', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Find calm routines, safety resources, and support for gender-based violence concerns.'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () {}, child: const Text('Mood check-in')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => context.go('/reports'), child: const Text('GBV support')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () {}, child: const Text('View wellness resources')),
          ],
        ),
      ),
    );
  }
}
