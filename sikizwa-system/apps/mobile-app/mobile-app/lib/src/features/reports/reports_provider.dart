import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class ReportRecord {
  ReportRecord({
    required this.title,
    required this.createdAt,
    required this.riskLevel,
    required this.moodStatus,
    required this.emotionalSummary,
    required this.description,
  });

  final String title;
  final DateTime createdAt;
  final String riskLevel;
  final String moodStatus;
  final String emotionalSummary;
  final String description;

  factory ReportRecord.fromJson(Map<String, dynamic> json) {
    final rawRisk = json['risk_level']?.toString() ?? json['riskLevel']?.toString() ?? 'low';
    final createdAt = DateTime.tryParse(
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
        ) ??
        DateTime.now();

    final type = json['type']?.toString().trim().isNotEmpty == true
        ? json['type'].toString()
        : 'support';
    final description = json['description']?.toString().trim().isNotEmpty == true
        ? json['description'].toString()
        : 'No summary available.';

    return ReportRecord(
      title: _formatTitle(type),
      createdAt: createdAt,
      riskLevel: _normalizeRisk(rawRisk),
      moodStatus: _moodStatusForRisk(_normalizeRisk(rawRisk)),
      emotionalSummary: description,
      description: description,
    );
  }

  static String _formatTitle(String type) {
    final formatted = type.replaceAll('_', ' ').trim();
    if (formatted.isEmpty) {
      return 'Support update';
    }
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  static String _normalizeRisk(String rawRisk) {
    switch (rawRisk.toLowerCase()) {
      case 'medium':
      case 'moderate':
        return 'medium';
      case 'high':
      case 'critical':
        return 'high';
      case 'emergency':
        return 'emergency';
      case 'low':
      default:
        return 'low';
    }
  }

  static String _moodStatusForRisk(String riskLevel) {
    switch (riskLevel) {
      case 'emergency':
        return 'Urgent';
      case 'high':
        return 'Elevated';
      case 'medium':
        return 'Steady';
      case 'low':
      default:
        return 'Calm';
    }
  }
}

final reportsProvider = FutureProvider.autoDispose<List<ReportRecord>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.get('/api/reports');

  if (response is! List) {
    return const <ReportRecord>[];
  }

  return response
      .whereType<Map>()
      .map((item) => ReportRecord.fromJson(Map<String, dynamic>.from(item)))
      .toList(growable: false);
});
