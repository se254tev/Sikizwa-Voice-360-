import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({
    super.key,
    required this.mode,
  });

  final PairingMode mode;

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

enum PairingMode { generate, link }

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _pairingCode = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.mode == PairingMode.generate) {
      _loadPairingCode();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadPairingCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = await ref.read(authProvider.notifier).requestPairingCode();
      if (!mounted) {
        return;
      }

      setState(() {
        _pairingCode = code;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitLink() async {
    final code = _codeController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (code.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Enter the pairing code, phone, and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).pairDevice(
        pairingCode: code,
        phone: phone,
        password: password,
      );
      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGenerate = widget.mode == PairingMode.generate;

    return Scaffold(
      appBar: AppBar(title: const Text('Device pairing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isGenerate ? 'Pair a phone safely' : 'Link this phone to your account',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isGenerate
                    ? 'Use this code on a phone to link a companion device. The code is valid for 10 minutes.'
                    : 'Enter the pairing code shown on your TV or smartwatch and sign in with your phone number.',
              ),
              const SizedBox(height: 24),
              if (isGenerate) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Pairing code'),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        Text(
                          _pairingCode,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _isLoading ? null : _loadPairingCode,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh code'),
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Pairing code'),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitLink,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Pair and sign in'),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
