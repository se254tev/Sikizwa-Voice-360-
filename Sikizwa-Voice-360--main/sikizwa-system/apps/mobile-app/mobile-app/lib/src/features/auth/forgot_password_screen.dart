import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors.dart';
import '../../core/errors/auth_error_messages.dart';
import '../../core/validation/form_validators.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/validated_text_field.dart';
import '../../shared/widgets/validation_summary.dart';
import 'repository/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isSubmitting = false;
  int _step = 0;
  List<String> _summaryErrors = const [];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  AuthRepository get _repo => AuthRepository(ref.read(apiServiceProvider));

  void _updateSummaryErrors() {
    final errors = <String>[];

    final phoneError = FormValidators.phone(
      _phoneController.text,
      required: true,
    );
    if (phoneError != null) {
      errors.add(phoneError);
    }

    if (_step >= 1) {
      final otpError = FormValidators.otp(_otpController.text);
      if (otpError != null) {
        errors.add(otpError);
      }
    }

    if (_step >= 2) {
      final passwordError = FormValidators.password(
        _passwordController.text,
        required: true,
      );
      if (passwordError != null) {
        errors.add(passwordError);
      }
    }

    setState(() => _summaryErrors = errors);
  }

  void _focusFirstInvalid() {
    final phoneError = FormValidators.phone(
      _phoneController.text,
      required: true,
    );
    if (phoneError != null) {
      _phoneFocusNode.requestFocus();
      return;
    }

    if (_step >= 1) {
      final otpError = FormValidators.otp(_otpController.text);
      if (otpError != null) {
        _otpFocusNode.requestFocus();
        return;
      }
    }

    if (_step >= 2) {
      final passwordError = FormValidators.password(
        _passwordController.text,
        required: true,
      );
      if (passwordError != null) {
        _passwordFocusNode.requestFocus();
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    _updateSummaryErrors();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      _focusFirstInvalid();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_step == 0) {
        await _repo.requestPasswordReset(phone: _phoneController.text);
        _showMessage(AuthErrorMessages.messageFor(AuthErrorMessages.resetCodeSent));
        setState(() => _step = 1);
        return;
      }

      if (_step == 1) {
        await _repo.verifyOtp(phone: _phoneController.text, otp: _otpController.text);
        _showMessage(AuthErrorMessages.messageFor(AuthErrorMessages.otpVerified));
        setState(() => _step = 2);
        return;
      }

      await _repo.resetPassword(
        phone: _phoneController.text,
        otp: _otpController.text,
        password: _passwordController.text,
      );

      _showMessage(AuthErrorMessages.messageFor(AuthErrorMessages.passwordUpdated));
      if (mounted) {
        context.go('/login');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatError(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
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
                    'Recover your account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step == 0
                        ? 'Enter your phone number to request a verification code.'
                        : _step == 1
                            ? 'Enter the 6-digit code sent to your phone.'
                            : 'Create a new password for your account.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ValidationSummaryBanner(errors: _summaryErrors),
                  AppValidatedTextField(
                    controller: _phoneController,
                    label: 'Phone number',
                    helperText: 'Use the phone number you registered with.',
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) => FormValidators.phone(value, required: true),
                  ),
                  if (_step >= 1) ...[
                    const SizedBox(height: 16),
                    AppValidatedTextField(
                      controller: _otpController,
                      label: 'Verification code',
                      helperText: 'Enter the 6-digit code we sent to your phone.',
                      focusNode: _otpFocusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.otp,
                    ),
                  ],
                  if (_step >= 2) ...[
                    const SizedBox(height: 16),
                    AppValidatedTextField(
                      controller: _passwordController,
                      label: 'New password',
                      helperText: 'Use at least 8 characters, including a letter and a number.',
                      focusNode: _passwordFocusNode,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) => FormValidators.password(value, required: true),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Processing...'),
                            ],
                          )
                        : Text(
                            _step == 0
                                ? 'Send verification code'
                                : _step == 1
                                    ? 'Verify code'
                                    : 'Reset password',
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _step == 0
                            ? () => context.go('/login')
                            : () => setState(() => _step = _step - 1),
                        child: Text(_step == 0 ? 'Back to sign in' : 'Back'),
                      ),
                    ],
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
