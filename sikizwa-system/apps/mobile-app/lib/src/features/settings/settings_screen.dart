import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../src/core/validation/form_validators.dart';
import '../../../src/shared/widgets/validated_text_field.dart';
import '../../../src/shared/widgets/validation_summary.dart';
import '../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool notificationsEnabled = true;
  bool privacyMode = false;
  String language = 'English';
  String voicePreference = 'Calm voice';
  String themePreference = 'System';

  final _contactFormKey = GlobalKey<FormState>();
  final _primaryNameController = TextEditingController();
  final _primaryPhoneController = TextEditingController();
  final _primaryRelationshipController = TextEditingController();
  final _secondaryNameController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _secondaryRelationshipController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _guardianRelationshipController = TextEditingController();

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
    _primaryNameController.dispose();
    _primaryPhoneController.dispose();
    _primaryRelationshipController.dispose();
    _secondaryNameController.dispose();
    _secondaryPhoneController.dispose();
    _secondaryRelationshipController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _guardianRelationshipController.dispose();
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<Map<String, String>> get _rawContacts => [
    {
      'name': _primaryNameController.text.trim(),
      'phone': _primaryPhoneController.text.trim(),
      'relationship': _primaryRelationshipController.text.trim(),
    },
    {
      'name': _secondaryNameController.text.trim(),
      'phone': _secondaryPhoneController.text.trim(),
      'relationship': _secondaryRelationshipController.text.trim(),
    },
    {
      'name': _guardianNameController.text.trim(),
      'phone': _guardianPhoneController.text.trim(),
      'relationship': _guardianRelationshipController.text.trim(),
    },
  ];

  void _syncSummaryErrors() {
    final errors = <String>[];

    for (final contact in _rawContacts) {
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

      final phoneError = FormValidators.phone(contact['phone']);
      if (phoneError != null && (contact['phone'] ?? '').isNotEmpty) {
        errors.add(phoneError);
      }
    }

    setState(() => _summaryErrors = errors);
  }

  FocusNode? _firstInvalidContactFocusNode() {
    for (final entry in [
      {
        'contact': _rawContacts[0],
        'name': _primaryNameFocusNode,
        'phone': _primaryPhoneFocusNode,
        'relationship': _primaryRelationshipFocusNode,
      },
      {
        'contact': _rawContacts[1],
        'name': _secondaryNameFocusNode,
        'phone': _secondaryPhoneFocusNode,
        'relationship': _secondaryRelationshipFocusNode,
      },
      {
        'contact': _rawContacts[2],
        'name': _guardianNameFocusNode,
        'phone': _guardianPhoneFocusNode,
        'relationship': _guardianRelationshipFocusNode,
      },
    ]) {
      final contact = entry['contact'] as Map<String, String>;
      final hasAnyValue =
          (contact['name'] ?? '').isNotEmpty ||
          (contact['phone'] ?? '').isNotEmpty ||
          (contact['relationship'] ?? '').isNotEmpty;

      if (!hasAnyValue) {
        continue;
      }

      if ((contact['name'] ?? '').isEmpty) {
        return entry['name'] as FocusNode;
      }

      if ((contact['phone'] ?? '').isEmpty ||
          FormValidators.phone(contact['phone']) != null) {
        return entry['phone'] as FocusNode;
      }

      if ((contact['relationship'] ?? '').isEmpty) {
        return entry['relationship'] as FocusNode;
      }
    }

    return null;
  }

  void _saveContacts() {
    _syncSummaryErrors();

    if (!(_contactFormKey.currentState?.validate() ?? false)) {
      _firstInvalidContactFocusNode()?.requestFocus();
      return;
    }

    _showMessage('Emergency contacts updated for this session.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroCard(theme: theme),
                  const SizedBox(height: 18),
                  _SettingsCard(
                    title: 'Preferences',
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: notificationsEnabled,
                          onChanged: (value) =>
                              setState(() => notificationsEnabled = value),
                          title: const Text('Notifications'),
                          subtitle: const Text(
                            'Receive reminders and support updates in your calm rhythm.',
                          ),
                        ),
                        SwitchListTile.adaptive(
                          value: privacyMode,
                          onChanged: (value) =>
                              setState(() => privacyMode = value),
                          title: const Text('Privacy shield'),
                          subtitle: const Text(
                            'Keep the experience focused on your comfort and control.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ChoiceGroup(
                          title: 'Language',
                          options: const ['English', 'Afrikaans', 'Xitsonga'],
                          selected: language,
                          onSelected: (value) =>
                              setState(() => language = value),
                        ),
                        const SizedBox(height: 12),
                        _ChoiceGroup(
                          title: 'Voice preferences',
                          options: const [
                            'Calm voice',
                            'Warm voice',
                            'Clear voice',
                          ],
                          selected: voicePreference,
                          onSelected: (value) =>
                              setState(() => voicePreference = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'Theme settings',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select your preferred visual tone for this session.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: ['System', 'Light', 'Dark']
                              .map(
                                (option) => _ThemeChip(
                                  label: option,
                                  selected: themePreference == option,
                                  onTap: () =>
                                      setState(() => themePreference = option),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'Emergency contact management',
                    child: Form(
                      key: _contactFormKey,
                      child: Column(
                        children: [
                          ValidationSummaryBanner(errors: _summaryErrors),
                          _ContactFieldCard(
                            title: 'Primary contact',
                            nameController: _primaryNameController,
                            phoneController: _primaryPhoneController,
                            relationshipController:
                                _primaryRelationshipController,
                            nameFocusNode: _primaryNameFocusNode,
                            phoneFocusNode: _primaryPhoneFocusNode,
                            relationshipFocusNode:
                                _primaryRelationshipFocusNode,
                          ),
                          const SizedBox(height: 12),
                          _ContactFieldCard(
                            title: 'Secondary contact',
                            nameController: _secondaryNameController,
                            phoneController: _secondaryPhoneController,
                            relationshipController:
                                _secondaryRelationshipController,
                            nameFocusNode: _secondaryNameFocusNode,
                            phoneFocusNode: _secondaryPhoneFocusNode,
                            relationshipFocusNode:
                                _secondaryRelationshipFocusNode,
                          ),
                          const SizedBox(height: 12),
                          _ContactFieldCard(
                            title: 'Guardian or trusted contact',
                            nameController: _guardianNameController,
                            phoneController: _guardianPhoneController,
                            relationshipController:
                                _guardianRelationshipController,
                            nameFocusNode: _guardianNameFocusNode,
                            phoneFocusNode: _guardianPhoneFocusNode,
                            relationshipFocusNode:
                                _guardianRelationshipFocusNode,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _saveContacts,
                              child: const Text('Save contacts locally'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      child: const Text('Sign out'),
                    ),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B2DA4), Color(0xFF7C3AED)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B2DA4).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A calm, secure space to fine-tune the experience and keep your support details easy to review.',
            style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options
              .map(
                (option) => _ThemeChip(
                  label: option,
                  selected: selected == option,
                  onTap: () => onSelected(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.primary.withOpacity(0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactFieldCard extends StatelessWidget {
  const _ContactFieldCard({
    required this.title,
    required this.nameController,
    required this.phoneController,
    required this.relationshipController,
    required this.nameFocusNode,
    required this.phoneFocusNode,
    required this.relationshipFocusNode,
  });

  final String title;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController relationshipController;
  final FocusNode nameFocusNode;
  final FocusNode phoneFocusNode;
  final FocusNode relationshipFocusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAnyValue =
        nameController.text.trim().isNotEmpty ||
        phoneController.text.trim().isNotEmpty ||
        relationshipController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          AppValidatedTextField(
            controller: nameController,
            label: 'Name',
            focusNode: nameFocusNode,
            textInputAction: TextInputAction.next,
            validator: hasAnyValue
                ? (value) =>
                      FormValidators.required(value, fieldLabel: 'contact name')
                : null,
          ),
          const SizedBox(height: 12),
          AppValidatedTextField(
            controller: phoneController,
            label: 'Phone',
            keyboardType: TextInputType.phone,
            focusNode: phoneFocusNode,
            textInputAction: TextInputAction.next,
            validator: hasAnyValue
                ? (value) => FormValidators.phone(value, required: true)
                : null,
          ),
          const SizedBox(height: 12),
          AppValidatedTextField(
            controller: relationshipController,
            label: 'Relationship',
            focusNode: relationshipFocusNode,
            textInputAction: TextInputAction.done,
            validator: hasAnyValue
                ? (value) =>
                      FormValidators.required(value, fieldLabel: 'relationship')
                : null,
          ),
        ],
      ),
    );
  }
}
