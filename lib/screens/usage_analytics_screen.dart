import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';

class UsageAnalyticsScreen extends StatelessWidget {
  const UsageAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final docs = state.documents;
    final meds = state.medicines.where((m) => m.isActive).toList();
    final missed = state.missedDoseCountNow();
    final takenToday = meds.where(_isTakenToday).length;
    final adherence = meds.isEmpty ? 0.0 : takenToday / meds.length;

    final upload7 = _uploadsByLastDays(docs, 7);
    final upload30 = _uploadsByLastDays(docs, 30);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Usage Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            runSpacing: 12,
            spacing: 12,
            children: [
              _statCard('Total Records', '${docs.length}', Icons.folder_rounded),
              _statCard('Uploads (7d)', '$upload7', Icons.cloud_upload_rounded),
              _statCard('Uploads (30d)', '$upload30', Icons.timeline_rounded),
              _statCard('Active Medicines', '${meds.length}', Icons.medication_rounded),
              _statCard('Adherence Today', '${(adherence * 100).toStringAsFixed(0)}%', Icons.check_circle_rounded),
              _statCard('Missed Doses', '$missed', Icons.warning_rounded),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Record Upload Trend (Last 7 Days)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildTrendRows(docs),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTrendRows(List<HealthDocument> docs) {
    final now = DateTime.now();
    final rows = <Widget>[];

    final counts = <int>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final count = docs.where((d) =>
          d.uploadedAt.year == day.year &&
          d.uploadedAt.month == day.month &&
          d.uploadedAt.day == day.day).length;
      counts.add(count);
    }

    final maxCount = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final count = counts[6 - i];
      final ratio = count / maxCount;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  '${day.day}/${day.month}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: AppTheme.divider,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  static bool _isTakenToday(MedicineReminder med) {
    final takenAt = med.lastTakenAt;
    if (takenAt == null) return false;
    final now = DateTime.now();
    return takenAt.year == now.year &&
        takenAt.month == now.month &&
        takenAt.day == now.day;
  }

  static int _uploadsByLastDays(List<HealthDocument> docs, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return docs.where((d) => d.uploadedAt.isAfter(cutoff)).length;
  }
}
