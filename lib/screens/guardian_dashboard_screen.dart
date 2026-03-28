import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class GuardianDashboardScreen extends StatelessWidget {
  const GuardianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final patient = state.linkedPatientProfile;
    final meds = state.medicines.where((m) => m.isActive).toList();
    final docs = state.documents;
    final takenToday = meds.where((m) {
      final t = m.lastTakenAt;
      if (t == null) return false;
      final now = DateTime.now();
      return t.year == now.year && t.month == now.month && t.day == now.day;
    }).length;
    final pendingDoses = meds.length - takenToday;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF8E44AD), Color(0xFF6C3483)]),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Guardian Dashboard', style: TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      patient == null
                          ? 'Link a patient to start monitoring'
                          : 'Monitoring 1 linked patient',
                      style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                    const SizedBox(height: 20),
                    Row(children: [
                      _GuardianStatCard('Patients', patient == null ? '0' : '1', Icons.elderly_rounded),
                      const SizedBox(width: 12),
                      _GuardianStatCard('Alerts', pendingDoses > 0 ? '$pendingDoses' : '0', Icons.notifications_none_rounded),
                      const SizedBox(width: 12),
                      _GuardianStatCard('Reports', '${docs.length}', Icons.folder_rounded),
                    ]),
                  ]),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: const SectionTitle(title: 'Your Patients'),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (patient == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: HealthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('No patient linked yet', style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text(
                            'Ask your parent to generate an invite code from their Profile page and enter it in your Profile.',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final conditions = patient.conditions;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: HealthCard(
                    child: Column(children: [
                      Row(children: [
                        Container(
                          width: 56, height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0E6FF), shape: BoxShape.circle),
                          child: Center(child: Text(
                            patient.name.isNotEmpty ? patient.name.substring(0, 1) : 'P',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF8E44AD))))),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(patient.name, style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                          Text('Linked Patient · Age ${patient.age ?? '-'} · ${patient.bloodGroup ?? '-'}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Text('ACTIVE', style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.secondary))),
                      ]),

                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppTheme.divider),
                      const SizedBox(height: 14),

                      // Medicines progress
                      Row(children: [
                        const Icon(Icons.medication_rounded, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Medicines today: $takenToday/${meds.length}', style: const TextStyle(fontSize: 14)),
                        const Spacer(),
                        const Icon(Icons.calendar_today_rounded, color: AppTheme.textHint, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          docs.isNotEmpty
                              ? 'Last report: ${docs.first.uploadedAt.day}/${docs.first.uploadedAt.month}/${docs.first.uploadedAt.year}'
                              : 'Last report: -',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                        ),
                      ]),
                      const SizedBox(height: 10),

                      // Conditions
                      Wrap(spacing: 6, runSpacing: 6,
                        children: conditions.map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2))),
                          child: Text(c.toString(), style: const TextStyle(
                            fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                        )).toList()),

                      const SizedBox(height: 14),

                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.folder_open_rounded, size: 16),
                          label: const Text('View Records'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            side: const BorderSide(color: AppTheme.divider),
                            foregroundColor: AppTheme.textSecondary))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.phone_rounded, size: 16, color: Colors.white),
                          label: const Text('Call Patient', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 42), backgroundColor: const Color(0xFF8E44AD)))),
                      ]),
                    ]),
                  ).animate().fadeIn(delay: 200.ms),
                );
              },
              childCount: 1,
            ),
          ),

          // ─── Recent alerts ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'Recent Updates'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HealthCard(
                    child: Column(children: [
                      if (patient == null)
                        const _AlertTile(Icons.info_outline_rounded,
                            'No linked patient updates yet',
                            'Link pending', AppTheme.textHint)
                      else ...[
                        _AlertTile(
                          Icons.medication_rounded,
                          'Today: $takenToday medicines marked taken',
                          'Live from patient app',
                          AppTheme.secondary,
                        ),
                        _AlertTile(
                          Icons.warning_rounded,
                          pendingDoses > 0
                              ? 'Pending doses today: $pendingDoses'
                              : 'No pending doses right now',
                          'Medication adherence',
                          pendingDoses > 0 ? AppTheme.warning : AppTheme.secondary,
                        ),
                        _AlertTile(
                          Icons.upload_file_rounded,
                          'Reports uploaded: ${docs.length}',
                          'Records overview',
                          AppTheme.primary,
                        ),
                      ],
                    ]),
                  ).animate().fadeIn(delay: 300.ms),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _GuardianStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _GuardianStatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ]),
    ));
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String message, time;
  final Color color;
  const _AlertTile(this.icon, this.message, this.time, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        ])),
      ]),
    );
  }
}
