import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../src/core/validation/form_validators.dart';
import '../../../src/shared/widgets/validated_text_field.dart';
import '../../../src/shared/widgets/validation_summary.dart';
import 'providers/auth_provider.dart';
import 'registration_helpers.dart';

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
  final _emailController = TextEditingController();
  final _roleController = TextEditingController(text: 'other');
  final _bloodGroupController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _locationController = TextEditingController();
  final _primaryNameController = TextEditingController();
  final _primaryPhoneController = TextEditingController();
  final _primaryRelationshipController = TextEditingController();
  final _secondaryNameController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _secondaryRelationshipController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _guardianRelationshipController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _primaryNameFocusNode = FocusNode();
  final _primaryPhoneFocusNode = FocusNode();
  final _primaryRelationshipFocusNode = FocusNode();
  final _secondaryNameFocusNode = FocusNode();
  final _secondaryPhoneFocusNode = FocusNode();
  final _secondaryRelationshipFocusNode = FocusNode();
  final _guardianNameFocusNode = FocusNode();
  final _guardianPhoneFocusNode = FocusNode();
  final _guardianRelationshipFocusNode = FocusNode();

  List<String> _summaryErrors = const [];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _medicalConditionsController.dispose();
    _locationController.dispose();
    _primaryNameController.dispose();
    _primaryPhoneController.dispose();
    _primaryRelationshipController.dispose();
    _secondaryNameController.dispose();
    _secondaryPhoneController.dispose();
    _secondaryRelationshipController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _guardianRelationshipController.dispose();
    _fullNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailFocusNode.dispose();
    _primaryNameFocusNode.dispose();
    _primaryPhoneFocusNode.dispose();
    _primaryRelationshipFocusNode.dispose();
    _secondaryNameFocusNode.dispose();
    _secondaryPhoneFocusNode.dispose();
    _secondaryRelationshipFocusNode.dispose();
    _guardianNameFocusNode.dispose();
    _guardianPhoneFocusNode.dispose();
    _guardianRelationshipFocusNode.dispose();
    super.dispose();
  }

  Map<String, String> _buildContact(
    TextEditingController nameController,
    TextEditingController phoneController,
    TextEditingController relationshipController,
  ) {
    return {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'relationship': relationshipController.text.trim(),
      'type': 'personal',
    };
  }

  List<Map<String, String>> get _emergencyContacts =>
      filterCompletedEmergencyContacts([
        _buildContact(
          _primaryNameController,
          _primaryPhoneController,
          _primaryRelationshipController,
        ),
        _buildContact(
          _secondaryNameController,
          _secondaryPhoneController,
          _secondaryRelationshipController,
        ),
        _buildContact(
          _guardianNameController,
          _guardianPhoneController,
          _guardianRelationshipController,
        ),
      ]);

  List<Map<String, String>> get _rawEmergencyContacts => [
    _buildContact(
      _primaryNameController,
      _primaryPhoneController,
      _primaryRelationshipController,
    ),
    _buildContact(
      _secondaryNameController,
      _secondaryPhoneController,
      _secondaryRelationshipController,
    ),
    _buildContact(
      _guardianNameController,
      _guardianPhoneController,
      _guardianRelationshipController,
    ),
  ];

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

    for (final contact in _rawEmergencyContacts) {
      final hasAnyValue =
          (contact['name'] ?? '').isNotEmpty ||
          (contact['phone'] ?? '').isNotEmpty ||
          (contact['relationship'] ?? '').isNotEmpty;

      if (!hasAnyValue) {
        continue;
      }

      if ((contact['name'] ?? '').isEmpty) {
        errors.add(
          'Please enter the contact name so we can save this emergency contact.',
        );
      }

      if ((contact['phone'] ?? '').isEmpty) {
        errors.add(
          'Please enter the contact phone number so we can save this emergency contact.',
        );
      }

      if ((contact['relationship'] ?? '').isEmpty) {
        errors.add('Please tell us how this contact is related to you.');
      }

      final invalidPhone = FormValidators.phone(contact['phone']);
      if (invalidPhone != null && (contact['phone'] ?? '').isNotEmpty) {
        errors.add(invalidPhone);
      }
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

    final primary = _rawEmergencyContacts[0];
    if (_contactNeedsValidation(primary)) {
      if ((primary['name'] ?? '').isEmpty) {
        return _primaryNameFocusNode;
      }
      if (FormValidators.phone(primary['phone']) != null) {
        return _primaryPhoneFocusNode;
      }
      if ((primary['relationship'] ?? '').isEmpty) {
        return _primaryRelationshipFocusNode;
      }
    }

    final secondary = _rawEmergencyContacts[1];
    if (_contactNeedsValidation(secondary)) {
      if ((secondary['name'] ?? '').isEmpty) {
        return _secondaryNameFocusNode;
      }
      if (FormValidators.phone(secondary['phone']) != null) {
        return _secondaryPhoneFocusNode;
      }
      if ((secondary['relationship'] ?? '').isEmpty) {
        return _secondaryRelationshipFocusNode;
      }
    }

    final guardian = _rawEmergencyContacts[2];
    if (_contactNeedsValidation(guardian)) {
      if ((guardian['name'] ?? '').isEmpty) {
        return _guardianNameFocusNode;
      }
      if (FormValidators.phone(guardian['phone']) != null) {
        return _guardianPhoneFocusNode;
      }
      if ((guardian['relationship'] ?? '').isEmpty) {
        return _guardianRelationshipFocusNode;
      }
    }

    return null;
  }

  bool _contactNeedsValidation(Map<String, String> contact) {
    return (contact['name'] ?? '').isNotEmpty ||
        (contact['phone'] ?? '').isNotEmpty ||
        (contact['relationship'] ?? '').isNotEmpty;
  }

  String _generateRegistrationPassword() {
    const allowed = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*';
    final random = Random.secure();
    return List.generate(12, (_) => allowed[random.nextInt(allowed.length)]).join();
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
    final password = _generateRegistrationPassword();

    final rawContacts = _rawEmergencyContacts;

    for (final contact in rawContacts) {
      final validation = validateEmergencyContact(contact);
      if (validation != null) {
        setState(() => _summaryErrors = [validation]);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(validation)));
        }
        return;
      }
    }

    try {
      await ref
          .read(authProvider.notifier)
          .register(
            fullName: fullName,
            phone: phone,
            password: password,
            role: _roleController.text.trim().isEmpty
                ? 'other'
                : _roleController.text.trim(),
            emergencyContacts: _emergencyContacts,
            email: normalizeOptionalField(_emailController.text),
            bloodGroup: normalizeOptionalField(_bloodGroupController.text),
            allergies: normalizeOptionalField(_allergiesController.text),
            medicalConditions: normalizeOptionalField(
              _medicalConditionsController.text,
            ),
            location: normalizeOptionalField(_locationController.text),
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
                            'We only need your full name and phone number to create your account safely.',
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
                            textInputAction: TextInputAction.done,
                            validator: (value) =>
                                FormValidators.phone(value, required: true),
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

}
