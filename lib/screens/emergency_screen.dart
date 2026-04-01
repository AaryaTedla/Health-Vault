import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// EMERGENCY SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _alertSent = false;
  final Set<String> _selectedPhones = <String>{};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final contacts = user?.emergencyContacts ?? [];
    final isLiveSharing = appState.isLiveLocationSharing;
    final remaining = appState.liveLocationRemaining;
    final statusNote = appState.liveLocationStatusNote;
    final crisisMode = appState.crisisModeEnabled;
    final responses = appState.guardianEmergencyResponses;
    final live = appState.liveLocationSnapshot;
    final lat = (live?['latitude'] as num?)?.toDouble();
    final lng = (live?['longitude'] as num?)?.toDouble();
    final updatedAt = live?['updatedAt'] as DateTime?;
    if (_selectedPhones.isEmpty && contacts.isNotEmpty) {
      _selectedPhones.addAll(contacts.map((c) => c.phone));
    }

    return Scaffold(
      backgroundColor: crisisMode ? const Color(0xFF111111) : Colors.white,
      appBar: AppBar(
        title: Text(
          crisisMode ? 'CRISIS MODE' : 'Emergency Alert',
          style: TextStyle(color: crisisMode ? Colors.amber : AppTheme.danger),
        ),
        backgroundColor: crisisMode ? const Color(0xFF111111) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ─── Big emergency button ────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: crisisMode ? 240 : 200, height: crisisMode ? 240 : 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.danger.withValues(alpha: 0.05 + _pulseController.value * 0.08),
                  border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.2 + _pulseController.value * 0.3),
                    width: 3 + _pulseController.value * 4),
                ),
                child: GestureDetector(
                  onTap: _alertSent ? null : () => _sendEmergencyAlert(),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _alertSent ? AppTheme.secondary : AppTheme.danger,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: (_alertSent ? AppTheme.secondary : AppTheme.danger).withValues(alpha: 0.4),
                        blurRadius: 30, spreadRadius: 5)],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(
                        _alertSent ? Icons.check_rounded : Icons.emergency_rounded,
                        color: Colors.white, size: crisisMode ? 60 : 48),
                      const SizedBox(height: 8),
                      Text(
                        _alertSent ? 'SENT!' : 'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: crisisMode ? 30 : 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 16),
            Text(
              _alertSent ? 'Alert sent to your emergency contacts!' : 'Press to alert your emergency contacts',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: _alertSent ? AppTheme.secondary : AppTheme.textSecondary),
              textAlign: TextAlign.center),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isLiveSharing
                    ? AppTheme.secondary.withValues(alpha: 0.10)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLiveSharing
                      ? AppTheme.secondary.withValues(alpha: 0.35)
                      : AppTheme.divider,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isLiveSharing
                            ? Icons.location_on_rounded
                            : Icons.location_off_rounded,
                        color: isLiveSharing ? AppTheme.secondary : AppTheme.textHint,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLiveSharing
                            ? 'Live location sharing is active'
                            : 'Live location is not active',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isLiveSharing
                              ? AppTheme.secondary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (isLiveSharing && remaining != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Auto stops in ${_formatRemaining(remaining)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (lat != null && lng != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Current: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    if (updatedAt != null)
                      Text(
                        'Updated: ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}:${updatedAt.second.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textHint,
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => appState.stopEmergencyLiveLocationSharing(),
                      icon: const Icon(Icons.stop_circle_outlined, size: 16),
                      label: const Text('Stop Sharing'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger),
                      ),
                    ),
                  ],
                  if (statusNote != null && statusNote.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      statusNote,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                    ),
                  ],
                ],
              ),
            ),

            if (responses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guardian Response',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    ...responses.take(2).map((r) {
                      final response = (r['response'] ?? '-').toString();
                      final eta = r['etaMinutes'] as int?;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          eta == null ? '• $response' : '• $response (ETA $eta min)',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ─── Contact selection ────────────────────────────────────────
            const Align(alignment: Alignment.centerLeft,
              child: Text('Alert will be sent to:', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700))),
            const SizedBox(height: 12),

            if (contacts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'No emergency contacts found. Add contacts from Profile to use SOS.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              )
            else
              ...contacts.map((contact) {
                final selected = _selectedPhones.contains(contact.phone);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HealthCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              contact.name.substring(0, 1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${contact.relation} · ${contact.phone}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: selected,
                          activeColor: AppTheme.primary,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedPhones.add(contact.phone);
                              } else {
                                _selectedPhones.remove(contact.phone);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // ─── Additional info ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What gets shared:', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...['Your name and phone number',
                      'Current time and location',
                      'Your blood group and conditions',
                      'Current medications'].map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.secondary, size: 16),
                      const SizedBox(width: 8),
                      Text(s, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ]),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (!_alertSent)
              BigButton(
                label: 'Send Emergency Alert',
                icon: Icons.emergency_rounded,
                color: AppTheme.danger,
                onTap: () => _sendEmergencyAlert(),
              ),

            const SizedBox(height: 12),

            // Call 108
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone_rounded, color: AppTheme.danger),
              label: const Text('Call Emergency Services (108)', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                side: const BorderSide(color: AppTheme.danger, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmergencyAlert() async {
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    final contacts = user?.emergencyContacts ?? [];
    final selected = contacts.where((c) => _selectedPhones.contains(c.phone)).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')));
      return;
    }

    for (final contact in selected) {
      NotificationService.showEmergencyNotification(
        contactName: contact.name,
        patientName: user?.name ?? 'Patient',
      );
    }

    final locationError = await appState.startEmergencyLiveLocationSharing();

    setState(() => _alertSent = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(locationError == null
          ? '🚨 Alert sent and live location sharing started.'
          : '🚨 Alert sent. Live location unavailable: $locationError'),
      backgroundColor: locationError == null ? AppTheme.secondary : AppTheme.warning,
      duration: const Duration(seconds: 4),
    ));
  }

  String _formatRemaining(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    final state = context.read<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDark, AppTheme.primary]),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3)),
                            child: Center(child: Text(
                              user?.name.substring(0, 1) ?? 'R',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700))),
                          ),
                          Positioned(bottom: 0, right: 0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 16))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(user?.name ?? 'Patient', style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '', style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(user?.accountType.toUpperCase() ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Health info ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: HealthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Health Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    _ProfileRow(Icons.cake_outlined, 'Age', '${user?.age ?? "--"} years'),
                    _ProfileRow(Icons.bloodtype_rounded, 'Blood Group', user?.bloodGroup ?? '--'),
                    _ProfileRow(Icons.phone_rounded, 'Phone', user?.phone ?? '--'),
                    if (user?.conditions.isNotEmpty ?? false)
                      _ProfileRow(Icons.medical_information_rounded, 'Conditions', user!.conditions.join(', ')),
                  ],
                ),
              ),
            ),
          ),

          // ─── Language selector ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: HealthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Preferred Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: AppConstants.languages.map((lang) {
                        final sel = state.selectedLanguage == lang;
                        return GestureDetector(
                          onTap: () => state.setLanguage(lang),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.primary : AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider)),
                            child: Text(lang, style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : AppTheme.textSecondary)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Emergency contacts ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: HealthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Emergency Contacts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primary)),
                    ]),
                    const SizedBox(height: 8),
                    ...(user?.emergencyContacts ?? []).map((ec) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: const BoxDecoration(color: AppTheme.surface, shape: BoxShape.circle),
                          child: Center(child: Text(ec.name.substring(0, 1),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(ec.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text('${ec.relation} · ${ec.phone}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ])),
                        Icon(Icons.call_rounded, color: AppTheme.secondary, size: 22),
                      ]),
                    )),
                  ],
                ),
              ),
            ),
          ),

          // ─── Settings menu ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: HealthCard(
                child: Column(
                  children: [
                    _SettingsTile(Icons.person_outline, 'Edit Profile', AppTheme.primary, () {}),
                    _SettingsTile(Icons.family_restroom_rounded, 'Manage Guardians', AppTheme.accent, () {}),
                    _SettingsTile(Icons.notifications_rounded, 'Notification Settings', const Color(0xFF9B59B6), () {}),
                    _SettingsTile(Icons.security_rounded, 'Privacy & Security', AppTheme.secondary, () {}),
                    _SettingsTile(Icons.help_outline_rounded, 'Help & Support', AppTheme.primary, () {}),
                    _SettingsTile(Icons.logout_rounded, 'Sign Out', AppTheme.danger,
                      () => state.signOut()),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SettingsTile(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20)),
      title: Text(label, style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w500,
        color: label == 'Sign Out' ? AppTheme.danger : AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
    );
  }
}
