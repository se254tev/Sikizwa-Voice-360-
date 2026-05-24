import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/admin_auth_provider.dart';

class AdminSignupScreen extends ConsumerStatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  ConsumerState<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends ConsumerState<AdminSignupScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final nationalId = _nationalIdController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || phone.isEmpty || email.isEmpty || nationalId.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill out every field.')),
        );
      }
      return;
    }

    if (password.length < 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 8 characters.')),
        );
      }
      return;
    }

    if (password != confirmPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
      }
      return;
    }

    try {
      await ref.read(adminAuthProvider.notifier).signup(
            fullName: fullName,
            phoneNumber: phone,
            email: email,
            nationalId: nationalId,
            password: password,
            confirmPassword: confirmPassword,
          );
      if (mounted) {
        context.go('/admin/dashboard');
      }
    } catch (_) {
      final error = ref.read(adminAuthProvider).error ?? 'Unable to create admin account.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Text('Create admin account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Secure admin signup for the Sikizwa backend.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone number'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email address'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nationalIdController,
                    decoration: const InputDecoration(labelText: 'National ID number'),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(labelText: 'Confirm password'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create admin account'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/admin/login'),
                    child: const Text('Back to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
