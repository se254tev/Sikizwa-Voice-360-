import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/admin_auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email/phone and password.')),
        );
      }
      return;
    }

    try {
      await ref.read(adminAuthProvider.notifier).login(identifier: identifier, password: password);
      if (mounted) {
        context.go('/admin/dashboard');
      }
    } catch (_) {
      final error = ref.read(adminAuthProvider).error ?? 'Unable to sign in. Please try again.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text('Admin login', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Secure access for dashboard administrators.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 24),
                TextField(
                  controller: _identifierController,
                  decoration: const InputDecoration(labelText: 'Email or phone number'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/admin/signup'),
                  child: const Text('Create an admin account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
