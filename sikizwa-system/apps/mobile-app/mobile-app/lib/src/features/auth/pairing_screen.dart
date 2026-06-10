import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../src/core/validation/form_validators.dart';
import '../../../src/shared/widgets/validated_text_field.dart';
import '../../../src/shared/widgets/validation_summary.dart';
import 'providers/auth_provider.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key, required this.mode});

  final PairingMode mode;

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

enum PairingMode { generate, link }

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  String _pairingCode = '';
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _summaryErrors = const [];

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
    _codeFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _syncSummaryErrors() {
    final errors = <String>[];

    final codeError = FormValidators.required(
      _codeController.text,
      fieldLabel: 'pairing code',
    );
    if (codeError != null) {
      errors.add(codeError);
    }

    final phoneError = FormValidators.phone(
      _phoneController.text,
      required: true,
    );
    if (phoneError != null) {
      errors.add(phoneError);
    }

    final passwordError = FormValidators.required(
      _passwordController.text,
      fieldLabel: 'password',
    );
    if (passwordError != null) {
      errors.add(passwordError);
    }

    setState(() {
      _summaryErrors = errors;
      _errorMessage = null;
    });
  }

  void _focusFirstInvalid() {
    final codeError = FormValidators.required(
      _codeController.text,
      fieldLabel: 'pairing code',
    );
    if (codeError != null) {
      _codeFocusNode.requestFocus();
      return;
    }

    final phoneError = FormValidators.phone(
      _phoneController.text,
      required: true,
    );
    if (phoneError != null) {
      _phoneFocusNode.requestFocus();
      return;
    }

    final passwordError = FormValidators.required(
      _passwordController.text,
      fieldLabel: 'password',
    );
    if (passwordError != null) {
      _passwordFocusNode.requestFocus();
    }
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
    _syncSummaryErrors();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      _focusFirstInvalid();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .pairDevice(
            pairingCode: _codeController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
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
                isGenerate
                    ? 'Pair a phone safely'
                    : 'Link this phone to your account',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
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
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
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
                ValidationSummaryBanner(errors: _summaryErrors),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppValidatedTextField(
                        controller: _codeController,
                        label: 'Pairing code',
                        helperText:
                            'Enter the code shown on your paired device.',
                        focusNode: _codeFocusNode,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) => FormValidators.required(
                          value,
                          fieldLabel: 'pairing code',
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppValidatedTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        helperText:
                            'Use your phone number with country code if needed.',
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            FormValidators.phone(value, required: true),
                      ),
                      const SizedBox(height: 16),
                      AppValidatedTextField(
                        controller: _passwordController,
                        label: 'Password',
                        helperText: 'Enter the password for your account.',
                        focusNode: _passwordFocusNode,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: (value) => FormValidators.required(
                          value,
                          fieldLabel: 'password',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitLink,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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
