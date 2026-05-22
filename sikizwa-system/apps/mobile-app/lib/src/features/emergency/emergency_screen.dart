import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

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
            const Text('Trigger a safe response team or send a distress signal anonymously.'),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () {}, child: const Text('Send emergency alert')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () {}, child: const Text('Share location with help center')),
          ],
        ),
      ),
    );
  }
}
