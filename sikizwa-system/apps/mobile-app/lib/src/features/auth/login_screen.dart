import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../src/core/validation/form_validators.dart';
import '../../../src/shared/widgets/validated_text_field.dart';
import '../../../src/shared/widgets/validation_summary.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  List<String> _summaryErrors = const [];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _syncSummaryErrors() {
    final errors = <String>[];

    final usernameError = FormValidators.loginIdentifier(
      _usernameController.text,
    );
    if (usernameError != null) {
      errors.add(usernameError);
    }

    final passwordError = FormValidators.required(
      _passwordController.text,
      fieldLabel: 'password',
    );
    if (passwordError != null) {
      errors.add(passwordError);
    }

    setState(() => _summaryErrors = errors);
  }

  void _focusFirstInvalid() {
    final usernameError = FormValidators.loginIdentifier(
      _usernameController.text,
    );
    if (usernameError != null) {
      _usernameFocusNode.requestFocus();
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

  Future<void> _submit() async {
    _syncSummaryErrors();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      _focusFirstInvalid();
      return;
    }

    try {
      await ref
          .read(authProvider.notifier)
          .login(
            identifier: _usernameController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      final err = ref.read(authProvider).error ?? e.toString();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to report safely.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ValidationSummaryBanner(errors: _summaryErrors),
                  if (auth.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Secure connection',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      auth.statusMessage ?? 'Preparing authentication service...',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  AppValidatedTextField(
                    controller: _usernameController,
                    label: 'Phone or username',
                    helperText: 'Use your registered phone number or username.',
                    focusNode: _usernameFocusNode,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.loginIdentifier,
                  ),
                  const SizedBox(height: 16),
                  AppValidatedTextField(
                    controller: _passwordController,
                    label: 'Password',
                    helperText: 'Enter the password for your account.',
                    focusNode: _passwordFocusNode,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) =>
                        FormValidators.required(value, fieldLabel: 'password'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(auth.statusMessage ?? 'Connecting to server...'),
                            ],
                          )
                        : const Text('Continue'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Create an account'),
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
