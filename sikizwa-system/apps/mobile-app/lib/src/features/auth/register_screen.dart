import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../src/core/validation/form_validators.dart';
import '../../../src/shared/widgets/validated_text_field.dart';
import '../../../src/shared/widgets/validation_summary.dart';
import 'providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  List<String> _summaryErrors = const [];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _syncSummaryErrors() {
    final errors = <String>[];

    final fullNameError = FormValidators.fullName(_fullNameController.text);
    if (fullNameError != null) {
      errors.add(fullNameError);
    }

    final phoneError = FormValidators.phone(
      _phoneController.text,
      required: true,
    );
    if (phoneError != null) {
      errors.add(phoneError);
    }

    final passwordError = FormValidators.password(
      _passwordController.text,
      required: true,
    );
    if (passwordError != null) {
      errors.add(passwordError);
    }

    final confirmPasswordError = _validateConfirmPassword(
      _confirmPasswordController.text,
    );
    if (confirmPasswordError != null) {
      errors.add(confirmPasswordError);
    }

    setState(() => _summaryErrors = errors);
  }

  FocusNode? _firstInvalidFocusNode() {
    final fullNameError = FormValidators.fullName(_fullNameController.text);
    if (fullNameError != null) {
      return _fullNameFocusNode;
    }

    final phoneError = FormValidators.phone(
      _phoneController.text,
      required: true,
    );
    if (phoneError != null) {
      return _phoneFocusNode;
    }

    final passwordError = FormValidators.password(
      _passwordController.text,
      required: true,
    );
    if (passwordError != null) {
      return _passwordFocusNode;
    }

    final confirmPasswordError = _validateConfirmPassword(
      _confirmPasswordController.text,
    );
    if (confirmPasswordError != null) {
      return _confirmPasswordFocusNode;
    }

    return null;
  }

  Future<void> _submit() async {
    _syncSummaryErrors();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      _firstInvalidFocusNode()?.requestFocus();
      return;
    }

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await ref.read(authProvider.notifier).register(
        fullName: fullName,
        phone: phone,
        password: password,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B2DA4), Color(0xFF7C3AED)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Create your account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Create a secure account with only your full name, phone number, and password.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ValidationSummaryBanner(errors: _summaryErrors),
                    if (auth.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
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
                    _sectionCard(
                      title: 'Required information',
                      subtitle:
                          'These fields are needed to create your account and start support.',
                      child: Column(
                        children: [
                          _buildField(
                            controller: _fullNameController,
                            label: 'Full name *',
                            focusNode: _fullNameFocusNode,
                            textInputAction: TextInputAction.next,
                            validator: FormValidators.fullName,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            controller: _phoneController,
                            label: 'Phone number *',
                            keyboardType: TextInputType.phone,
                            focusNode: _phoneFocusNode,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                FormValidators.phone(value, required: true),
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            controller: _passwordController,
                            label: 'Password *',
                            focusNode: _passwordFocusNode,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                FormValidators.password(value, required: true),
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            controller: _confirmPasswordController,
                            label: 'Confirm password *',
                            focusNode: _confirmPasswordFocusNode,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: _validateConfirmPassword,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(auth.statusMessage ?? 'Connecting to server...'),
                                ],
                              )
                            : const Text(
                                'Create account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Back to sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return AppValidatedTextField(
      controller: controller,
      label: label,
      helperText: helperText,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
    );
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value?.trim() ?? '';

    if (confirmPassword.isEmpty) {
      return 'Please re-enter your password.';
    }

    if (confirmPassword != _passwordController.text.trim()) {
      return 'Passwords do not match.';
    }

    return null;
  }
}
