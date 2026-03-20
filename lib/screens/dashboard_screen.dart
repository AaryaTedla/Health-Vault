import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import 'emergency_screen.dart';
import 'upload_document_screen.dart';
import 'medical_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final name = user?.name.split(' ').first ?? 'there';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning'
      : hour < 17 ? 'Good afternoon' : 'Good evening';
    final docs = appState.documents;
    final meds = appState.medicines;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [

          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDark, AppTheme.primary, Color(0xFF2196F3)]),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32))),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$greeting, $name 👋', style: const TextStyle(
                            color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          const Text('Your health, beautifully organised',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ])),
                      Stack(children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_rounded,
                            color: Colors.white, size: 28),
                          onPressed: () {}),
                        Positioned(top: 8, right: 8,
                          child: Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent, shape: BoxShape.circle))),
                      ]),
                    ]),
                    const SizedBox(height: 18),
                    Row(children: [
                      _StatCard(
                        label: 'Documents',
                        value: '${docs.length}',
                        icon: Icons.folder_rounded),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Medicines',
                        value: '${meds.length}',
                        icon: Icons.medication_rounded),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Active Meds',
                        value: '${meds.where((m) => m.isActive).length}',
                        icon: Icons.check_circle_rounded),
                    ]),
                  ]),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // Emergency button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Material(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EmergencyScreen())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                    child: Row(children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.emergency_rounded,
                          color: Colors.white, size: 26)),
                      const SizedBox(width: 14),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency Alert', style: TextStyle(
                            color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.w700)),
                          Text('Alert your emergency contacts instantly',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ])),
                      const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 28),
                    ]),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Quick Actions', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
                const SizedBox(height: 14),
                Row(children: [
                  _QuickAction(
                    icon: Icons.upload_file_rounded,
                    label: 'Upload\nReport',
                    color: AppTheme.primary,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => const UploadDocumentScreen()))),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.history_rounded,
                    label: 'Medical\nHistory',
                    color: const Color(0xFF8E44AD),
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => const MedicalHistoryScreen()))),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.family_restroom_rounded,
                    label: 'Guardian\nAlerts',
                    color: AppTheme.accent,
                    onTap: () => _showGuardianDialog(context, user)),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.health_and_safety_rounded,
                    label: 'Health\nProfile',
                    color: AppTheme.secondary,
                    onTap: () => _showHealthProfile(context, user)),
                ]),
              ]),
            ).animate().fadeIn(delay: 150.ms),
          ),

          // Daily tip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.lightbulb_rounded,
                      color: AppTheme.secondary, size: 24)),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's Health Tip", style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppTheme.secondary)),
                      SizedBox(height: 4),
                      Text(
                        '🌟 Take a 20-minute walk after lunch — it helps control blood sugar and improves your mood!',
                        style: TextStyle(fontSize: 14,
                          color: AppTheme.textPrimary, height: 1.5)),
                    ])),
                ]),
              ).animate().fadeIn(delay: 200.ms),
            ),
          ),

          // Medicines section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Today's Medicines", style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                if (meds.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider)),
                    child: const Center(child: Text(
                      'No medicines added yet.\nGo to Medicines tab to add.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.5))))
                else
                  ...meds.take(4).map((med) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider)),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.medication_rounded,
                          color: AppTheme.primary, size: 24)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.medicineName, style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                          Text('${med.dosage} · ${med.frequency}',
                            style: const TextStyle(fontSize: 13,
                              color: AppTheme.textSecondary)),
                        ])),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: med.isActive
                            ? AppTheme.secondary.withValues(alpha: 0.1)
                            : AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                        child: Text(med.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: med.isActive
                              ? AppTheme.secondary : AppTheme.danger))),
                    ]),
                  )),
              ]),
            ).animate().fadeIn(delay: 250.ms),
          ),

          // Recent documents
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Recent Documents', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                if (docs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider)),
                    child: const Center(child: Text(
                      'No documents uploaded yet.\nTap Upload Report to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.5))))
                else
                  ...docs.take(3).map((doc) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider)),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.description_rounded,
                          color: AppTheme.primary, size: 26)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.name, style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                          Text('${doc.hospitalName} · ${doc.documentType}',
                            style: const TextStyle(fontSize: 12,
                              color: AppTheme.textSecondary)),
                        ])),
                      if (doc.aiSummary != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8)),
                          child: const Text('AI', style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: AppTheme.primary))),
                    ]),
                  )),
              ]),
            ).animate().fadeIn(delay: 300.ms),
          ),

          // Health profile card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.health_and_safety_rounded,
                      color: AppTheme.primary, size: 22),
                    SizedBox(width: 8),
                    Text('Health Profile', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _InfoChip(label: 'Age',
                      value: user?.age != null ? '${user!.age} yrs' : '--'),
                    _InfoChip(label: 'Blood',
                      value: user?.bloodGroup ?? '--'),
                    if (user?.conditions.isNotEmpty ?? false)
                      ...user!.conditions.map((c) =>
                        _InfoChip(label: 'Condition', value: c)),
                    if (user?.conditions.isEmpty ?? true)
                      const _InfoChip(label: 'Conditions', value: 'None added'),
                  ]),
                ]),
              ).animate().fadeIn(delay: 350.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _showGuardianDialog(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.family_restroom_rounded, color: AppTheme.accent),
          SizedBox(width: 8),
          Text('Guardian Alerts'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Emergency contacts who will be alerted:',
            style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          if (user?.emergencyContacts.isEmpty ?? true)
            const Text('No emergency contacts added yet.',
              style: TextStyle(color: AppTheme.textHint))
          else
            ...user.emergencyContacts.map((ec) => ListTile(
              leading: const Icon(Icons.person_rounded, color: AppTheme.primary),
              title: Text(ec.name),
              subtitle: Text('${ec.relation} · ${ec.phone}'),
            )),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
        ],
      ),
    );
  }

  void _showHealthProfile(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.health_and_safety_rounded, color: AppTheme.secondary),
          SizedBox(width: 8),
          Text('Health Profile'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileRow('Name', user?.name ?? '--'),
            _profileRow('Age', user?.age != null ? '${user!.age} years' : '--'),
            _profileRow('Blood Group', user?.bloodGroup ?? '--'),
            _profileRow('Phone', user?.phone ?? '--'),
            _profileRow('Conditions',
              user?.conditions.isNotEmpty ?? false
                ? user!.conditions.join(', ') : 'None'),
          ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(
          fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        Expanded(child: Text(value, style: const TextStyle(
          fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    ));
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w600, color: color),
            textAlign: TextAlign.center),
        ]),
      ),
    ));
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15))),
      child: Text('$label: $value', style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary)),
    );
  }
}