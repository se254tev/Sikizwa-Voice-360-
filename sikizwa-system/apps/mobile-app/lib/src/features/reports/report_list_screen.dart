import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import 'reports_provider.dart';

class ReportListScreen extends ConsumerStatefulWidget {
  const ReportListScreen({super.key});

  @override
  ConsumerState<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends ConsumerState<ReportListScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  bool _anonymousSubmission = false;
  bool _isSubmitting = false;
  bool _reportForMe = true;
  String _selectedIncidentType = 'Physical Violence';
  String? _submitError;

  static const _incidentOptions = [
    'Physical Violence',
    'Sexual Violence',
    'Emotional Abuse',
    'Economic Abuse',
    'Child Abuse',
    'Domestic Violence',
    'Harassment',
    'Stalking',
    'Forced Marriage',
    'Human Trafficking',
    'Online Abuse',
    'Other',
  ];

  int get _descriptionLength => _descriptionController.text.trim().length;
  static const _descriptionMaxLength = 500;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/api/reports', data: {
        'reportType': 'problem',
        'incidentType': _selectedIncidentType,
        'reportedFor': _reportForMe ? 'me' : 'someone_else',
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'anonymousSubmission': _anonymousSubmission,
        'priority': _priority,
      });

      ref.invalidate(reportsProvider);

      _locationController.clear();
      _descriptionController.clear();
      setState(() {
        _priority = 'medium';
        _anonymousSubmission = false;
        _selectedIncidentType = 'Physical Violence';
        _reportForMe = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully.')),
      );
    } catch (error) {
      setState(() {
        _submitError = error.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Report a problem')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: reportsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _ReportErrorState(
              message: error.toString(),
              theme: theme,
            ),
            data: (reports) {
              final highestRisk = reports
                  .map((report) => report.riskLevel)
                  .fold<String>('low', (current, next) {
                    if (current == 'emergency' || next == 'emergency') {
                      return 'emergency';
                    }
                    if (current == 'high' || next == 'high') {
                      return 'high';
                    }
                    return 'low';
                  });

              final summaryMessage = reports.isEmpty
                  ? 'No problem reports are available yet. Start a new report to build your support history.'
                  : 'Showing ${reports.length} recent problem report${reports.length == 1 ? '' : 's'} with ${highestRisk == 'low' ? 'calm' : highestRisk} support signals.';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(
                    title: 'Your latest problem reports',
                    subtitle: summaryMessage,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _ReportSubmissionForm(
                    formKey: _formKey,
                    reportForMe: _reportForMe,
                    onReportForChanged: (value) => setState(() => _reportForMe = value),
                    incidentOptions: _incidentOptions,
                    selectedIncidentType: _selectedIncidentType,
                    onIncidentTypeChanged: (value) => setState(() => _selectedIncidentType = value),
                    locationController: _locationController,
                    descriptionController: _descriptionController,
                    descriptionLength: _descriptionLength,
                    descriptionMaxLength: _descriptionMaxLength,
                    priority: _priority,
                    anonymousSubmission: _anonymousSubmission,
                    isSubmitting: _isSubmitting,
                    submitError: _submitError,
                    onPriorityChanged: (value) => setState(() => _priority = value),
                    onAnonymousChanged: (value) => setState(() => _anonymousSubmission = value),
                    onSubmit: _submitReport,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: reports.isEmpty
                        ? _EmptyReportState(theme: theme)
                        : ListView.separated(
                            itemCount: reports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final report = reports[index];
                              return _ReportCard(report: report);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReportSubmissionForm extends StatelessWidget {
  const _ReportSubmissionForm({
    required this.formKey,
    required this.reportForMe,
    required this.onReportForChanged,
    required this.incidentOptions,
    required this.selectedIncidentType,
    required this.onIncidentTypeChanged,
    required this.locationController,
    required this.descriptionController,
    required this.descriptionLength,
    required this.descriptionMaxLength,
    required this.priority,
    required this.anonymousSubmission,
    required this.isSubmitting,
    required this.submitError,
    required this.onPriorityChanged,
    required this.onAnonymousChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool reportForMe;
  final ValueChanged<bool> onReportForChanged;
  final List<String> incidentOptions;
  final String selectedIncidentType;
  final ValueChanged<String> onIncidentTypeChanged;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final int descriptionLength;
  final int descriptionMaxLength;
  final String priority;
  final bool anonymousSubmission;
  final bool isSubmitting;
  final String? submitError;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Submit a new problem report', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ToggleButtons(
                isSelected: [reportForMe, !reportForMe],
                onPressed: (index) => onReportForChanged(index == 0),
                borderRadius: BorderRadius.circular(16),
                selectedColor: theme.colorScheme.onPrimary,
                fillColor: theme.colorScheme.primary,
                color: theme.colorScheme.onSurface,
                constraints: const BoxConstraints(minHeight: 44, minWidth: 140),
                children: const [
                  Text('Report for Me'),
                  Text('Report for Someone Else'),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedIncidentType,
                decoration: const InputDecoration(labelText: 'Type of incident'),
                items: incidentOptions
                    .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onIncidentTypeChanged(value);
                  }
                },
                validator: (value) => value?.trim().isEmpty == true ? 'Please select a type of incident.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Where did this happen? (optional)',
                ),
                maxLines: 2,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Describe the incident',
                  hintText: 'Share the details, who was involved, and what happened.',
                  alignLabelWithHint: true,
                  helperText: 'Minimum 15 characters',
                  counterText: '$descriptionLength / $descriptionMaxLength',
                ),
                minLines: 4,
                maxLines: 6,
                maxLength: descriptionMaxLength,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Please describe the incident.';
                  }
                  if (trimmed.length < 15) {
                    return 'Please provide a longer description (at least 15 characters).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                      ],
                      onChanged: onPriorityChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SwitchListTile(
                      value: anonymousSubmission,
                      onChanged: onAnonymousChanged,
                      title: const Text('Submit anonymously'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              if (submitError != null) ...[
                const SizedBox(height: 12),
                Text(submitError!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  final String title;
  final String subtitle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final ReportRecord report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = switch (report.riskLevel) {
      'emergency' => Colors.red.shade700,
      'high' => Colors.orange.shade700,
      _ => Colors.green.shade700,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    report.riskLevel.toUpperCase(),
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.moodStatus,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              report.emotionalSummary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              'Created ${report.createdAt.toLocal().toString().substring(0, 16)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReportState extends StatelessWidget {
  const _EmptyReportState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'No problem reports yet',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Problem reports will appear here once your support updates are saved.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ReportErrorState extends StatelessWidget {
  const _ReportErrorState({required this.message, required this.theme});

  final String message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Unable to load reports',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
