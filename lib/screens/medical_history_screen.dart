import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import 'appointment_screen.dart';
import 'usage_analytics_screen.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: 'Medical History',
              subtitle: 'Live records from your account',
              height: 120,
              actions: [
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  onPressed: () => _exportData(context),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textHint,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Dashboard'),
                  Tab(text: 'Timeline'),
                  Tab(text: 'AI Insights'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildDashboard(appState),
            _buildTimeline(appState),
            _buildAIInsights(appState.currentUser?.conditions ?? const []),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(AppState appState) {
    final docs = appState.documents;
    final meds = appState.medicines;
    final appointments = appState.appointments;

    final activeMeds = meds.where((m) => m.isActive).toList();
    final takenToday = activeMeds.where(_isTakenToday).length;
    final adherence = activeMeds.isEmpty ? 0.0 : takenToday / activeMeds.length;
    final upcomingAppointments = appointments
        .where((a) => a.dateTime.isAfter(DateTime.now()) && !a.completed)
        .length;

    final events = _eventsByDay(docs, meds, appointments);
    final maxY = events.isEmpty ? 1.0 : events.reduce((a, b) => a > b ? a : b).toDouble().clamp(1.0, 999.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  'Records',
                  '${docs.length}',
                  Icons.folder_rounded,
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  'Active Meds',
                  '${activeMeds.length}',
                  Icons.medication_rounded,
                  AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  'Upcoming',
                  '$upcomingAppointments',
                  Icons.event_available_rounded,
                  AppTheme.accent,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 16),
          HealthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medicine Adherence Today',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '$takenToday of ${activeMeds.length} active medicines marked taken',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: adherence,
                    minHeight: 10,
                    backgroundColor: AppTheme.divider,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 130.ms),
          const SizedBox(height: 16),
          HealthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last 7 Days Activity',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Based on uploads, medicine updates, and appointments.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 190,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY + 1,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: AppTheme.divider, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              const days = ['-6', '-5', '-4', '-3', '-2', '-1', 'Today'];
                              final i = v.toInt();
                              if (i < 0 || i >= days.length) return const SizedBox.shrink();
                              return Text(
                                days[i],
                                style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            events.length,
                            (i) => FlSpot(i.toDouble(), events[i].toDouble()),
                          ),
                          isCurved: true,
                          color: AppTheme.primary,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primary.withValues(alpha: 0.09),
                          ),
                          dotData: FlDotData(
                            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                              radius: 3.5,
                              color: AppTheme.primary,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 16),
          HealthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insights & Planning',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsageAnalyticsScreen()),
                    ),
                    icon: const Icon(Icons.analytics_rounded),
                    label: const Text('Usage Analytics Dashboard'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppointmentScreen()),
                    ),
                    icon: const Icon(Icons.event_available_rounded),
                    label: const Text('Appointment Scheduler'),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 220.ms),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildTimeline(AppState appState) {
    final items = _buildTimelineItems(appState);
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No medical activity yet.\nUpload records or add medicines to build timeline.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final isLast = i == items.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 56,
                    color: AppTheme.divider,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.when,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAIInsights(List<String> conditions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: HealthCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Insights Snapshot',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              conditions.isEmpty
                  ? 'No known conditions added yet. Add profile details and upload reports for richer AI insights.'
                  : 'Current conditions on file: ${conditions.join(', ')}',
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tip: Open AI Chat for personalized explanations based on your latest records and medicine schedule.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final filePath = await context.read<AppState>().exportDataToJsonFile();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          filePath == null
              ? 'Could not export data right now.'
              : 'Data exported successfully. File path: $filePath',
        ),
      ),
    );
  }

  bool _isTakenToday(MedicineReminder med) {
    final t = med.lastTakenAt;
    if (t == null) return false;
    final now = DateTime.now();
    return t.year == now.year && t.month == now.month && t.day == now.day;
  }

  List<int> _eventsByDay(
    List<HealthDocument> docs,
    List<MedicineReminder> meds,
    List<Appointment> appointments,
  ) {
    final now = DateTime.now();
    final days = List<int>.filled(7, 0);

    for (final d in docs) {
      final offset = now.difference(DateTime(d.uploadedAt.year, d.uploadedAt.month, d.uploadedAt.day)).inDays;
      if (offset >= 0 && offset < 7) {
        days[6 - offset] += 1;
      }
    }

    for (final m in meds) {
      final t = m.lastTakenAt;
      if (t == null) continue;
      final offset = now.difference(DateTime(t.year, t.month, t.day)).inDays;
      if (offset >= 0 && offset < 7) {
        days[6 - offset] += 1;
      }
    }

    for (final a in appointments) {
      final dt = a.dateTime;
      final offset = now.difference(DateTime(dt.year, dt.month, dt.day)).inDays;
      if (offset >= 0 && offset < 7) {
        days[6 - offset] += 1;
      }
    }

    return days;
  }

  List<_TimelineItem> _buildTimelineItems(AppState state) {
    final items = <_TimelineItem>[];

    for (final d in state.documents) {
      items.add(
        _TimelineItem(
          at: d.uploadedAt,
          icon: Icons.description_rounded,
          color: AppTheme.primary,
          title: d.name,
          subtitle: '${d.hospitalName} • ${d.documentType}',
        ),
      );
    }

    for (final m in state.medicines) {
      final t = m.lastTakenAt;
      if (t == null) continue;
      items.add(
        _TimelineItem(
          at: t,
          icon: Icons.check_circle_rounded,
          color: AppTheme.secondary,
          title: 'Marked taken: ${m.medicineName}',
          subtitle: '${m.dosage} • ${m.frequency}',
        ),
      );
    }

    for (final a in state.appointments) {
      items.add(
        _TimelineItem(
          at: a.dateTime,
          icon: a.completed ? Icons.task_alt_rounded : Icons.event_note_rounded,
          color: a.completed ? AppTheme.secondary : AppTheme.accent,
          title: a.title,
          subtitle: '${a.hospital}${a.completed ? ' • Completed' : ''}',
        ),
      );
    }

    items.sort((a, b) => b.at.compareTo(a.at));
    return items.take(60).toList(growable: false);
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem {
  final DateTime at;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _TimelineItem({
    required this.at,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  String get when {
    final d = at;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} • $hh:$mm';
  }
}
