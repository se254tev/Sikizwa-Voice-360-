import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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

  String? _validateContact(Map<String, String> contact) {
    if (contact['name']!.isEmpty || contact['phone']!.isEmpty || contact['relationship']!.isEmpty) {
      return 'Complete all emergency contact fields.';
    }

    final phone = contact['phone']!;
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
      return 'Emergency contact phone numbers must be valid international numbers.';
    }

    return null;
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (fullName.isEmpty || phone.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your full name, phone, and password.')),
        );
      }
      return;
    }

    final emergencyContacts = [
      _buildContact(_primaryNameController, _primaryPhoneController, _primaryRelationshipController),
      _buildContact(_secondaryNameController, _secondaryPhoneController, _secondaryRelationshipController),
      _buildContact(_guardianNameController, _guardianPhoneController, _guardianRelationshipController),
    ];

    for (final contact in emergencyContacts) {
      final validation = _validateContact(contact);
      if (validation != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validation)));
        }
        return;
      }
    }

    try {
      await ref.read(authProvider.notifier).register(
        fullName: fullName,
        phone: phone,
        password: password,
        role: _roleController.text.trim().isEmpty ? 'other' : _roleController.text.trim(),
        emergencyContacts: emergencyContacts,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        bloodGroup: _bloodGroupController.text.trim().isEmpty ? null : _bloodGroupController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty ? null : _allergiesController.text.trim(),
        medicalConditions: _medicalConditionsController.text.trim().isEmpty ? null : _medicalConditionsController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      final err = ref.read(authProvider).error ?? e.toString();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Get started', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Create your emergency profile so help can reach you quickly.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bloodGroupController,
                decoration: const InputDecoration(labelText: 'Blood group (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _allergiesController,
                decoration: const InputDecoration(labelText: 'Allergies (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _medicalConditionsController,
                decoration: const InputDecoration(labelText: 'Medical conditions (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location (optional)'),
              ),
              const SizedBox(height: 24),
              const Text('Emergency contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildContactCard('Primary contact', _primaryNameController, _primaryPhoneController, _primaryRelationshipController),
              const SizedBox(height: 12),
              _buildContactCard('Secondary contact', _secondaryNameController, _secondaryPhoneController, _secondaryRelationshipController),
              const SizedBox(height: 12),
              _buildContactCard('Guardian or trusted contact', _guardianNameController, _guardianPhoneController, _guardianRelationshipController),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create account'),
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
    );
  }

  Widget _buildContactCard(
    String title,
    TextEditingController nameController,
    TextEditingController phoneController,
    TextEditingController relationshipController,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 8),
            TextField(controller: relationshipController, decoration: const InputDecoration(labelText: 'Relationship')),
          ],
        ),
      ),
    );
  }
}
