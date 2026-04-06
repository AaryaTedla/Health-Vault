import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import 'dashboard_screen.dart';
import 'documents_screen.dart';
import 'medicine_screen.dart';
import 'ai_chat_screen.dart';
import 'guardian_dashboard_screen.dart';
import 'auth_screens.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isGuardian = context.watch<AppState>().isGuardian;
    final screens = isGuardian
        ? const [
            GuardianDashboardScreen(),
            DocumentsScreen(),
            MedicineScreen(),
            AIChatScreen(),
            _ProfileScreen(),
          ]
        : const [
            DashboardScreen(),
            DocumentsScreen(),
            MedicineScreen(),
            AIChatScreen(),
            _ProfileScreen(),
          ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: isGuardian ? 'Guardian' : 'Home', index: 0, current: _currentIndex, onTap: _setTab),
                _NavItem(icon: Icons.folder_rounded, label: 'Records', index: 1, current: _currentIndex, onTap: _setTab),
                _NavItem(icon: Icons.medication_rounded, label: 'Medicines', index: 2, current: _currentIndex, onTap: _setTab),
                _NavItem(icon: Icons.smart_toy_rounded, label: 'AI Chat', index: 3, current: _currentIndex, onTap: _setTab),
                _NavItem(icon: Icons.person_rounded, label: 'Profile', index: 4, current: _currentIndex, onTap: _setTab),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setTab(int i) => setState(() => _currentIndex = i);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final void Function(int) onTap;

  const _NavItem({required this.icon, required this.label,
    required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: selected ? AppTheme.primary : AppTheme.textHint, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? AppTheme.primary : AppTheme.textHint),
              overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

// ─── Profile Screen ──────────────────────────────────────────────────────────
class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;

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
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32))),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(children: [
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3)),
                      child: Center(child: Text(
                        user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)))),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        (user?.accountType ?? 'patient').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                  ]),
                ),
              ),
            ),
          ),

          // Health info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Health Information', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  _infoRow(Icons.person_outline, 'Name', user?.name ?? 'Not set'),
                  _infoRow(Icons.cake_outlined, 'Age', user?.age != null ? '${user!.age} years' : 'Not set'),
                  _infoRow(Icons.bloodtype_rounded, 'Blood Group', user?.bloodGroup ?? 'Not set'),
                  _infoRow(Icons.phone_rounded, 'Phone', user?.phone ?? 'Not set'),
                  if (user?.conditions.isNotEmpty ?? false)
                    _infoRow(Icons.medical_information_rounded, 'Conditions', user!.conditions.join(', ')),
                ]),
              ),
            ),
          ),

          // Language
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('AI Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8,
                    children: ['English', 'Hindi', 'Telugu', 'Kannada', 'Tamil'].map((lang) {
                      final sel = state.selectedLanguage == lang;
                      return GestureDetector(
                        onTap: () => state.setLanguage(lang),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.primary : AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider)),
                          child: Text(lang, style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppTheme.textSecondary)),
                        ),
                      );
                    }).toList()),
                ]),
              ),
            ),
          ),

          // Emergency contacts
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Emergency Contacts', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                      if (!state.isGuardian)
                        TextButton.icon(
                          onPressed: () => _showAddContactDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add'),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: const Text('Patient-only', style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          )),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (user?.emergencyContacts.isEmpty ?? true)
                    const Text(
                      'No contacts added yet. Add at least one contact for SOS.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    )
                  else
                    ...user!.emergencyContacts.map((ec) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: const BoxDecoration(
                            color: AppTheme.surface, shape: BoxShape.circle),
                          child: Center(child: Text(ec.name[0],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(ec.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text('${ec.relation} · ${ec.phone}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ])),
                        if (!state.isGuardian)
                          IconButton(
                            onPressed: () => state.removeEmergencyContact(ec.phone),
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 22),
                          ),
                      ]),
                    )),
                ]),
              ),
            ),
          ),

          // Pairing
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Family Pairing', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (state.isPatient) ...[
                    const Text(
                      'Generate an invite code and ask your guardian to enter it in their app.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final code = await state.generatePairingCode();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(code == null
                                    ? 'Could not generate code. Please retry.'
                                    : 'Invite code generated: $code'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code_rounded, size: 18),
                          label: const Text('Generate Invite Code'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => state.refreshPendingPairingRequests(),
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh requests',
                      ),
                    ]),
                    if ((state.activePairingCode ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(children: [
                          const Text('Active Code: ', style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                          Expanded(
                            child: Text(
                              state.activePairingCode!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (state.pendingPairingRequests.isEmpty)
                      const Text(
                        'No pending guardian requests.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      )
                    else
                      ...state.pendingPairingRequests.map((req) {
                        final guardianName = (req['guardianName'] ?? 'Guardian').toString();
                        final guardianEmail = (req['guardianEmail'] ?? '').toString();
                        final requestId = (req['requestId'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(guardianName, style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                                if (guardianEmail.isNotEmpty)
                                  Text(guardianEmail, style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textSecondary)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: requestId.isEmpty ? null : () async {
                                        final ok = await state.rejectPairingRequest(requestId);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(ok
                                              ? 'Request rejected.'
                                              : 'Could not reject request.')),
                                        );
                                      },
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: requestId.isEmpty ? null : () async {
                                        final ok = await state.approvePairingRequest(requestId);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(ok
                                              ? 'Guardian approved and linked.'
                                              : 'Could not approve request.')),
                                        );
                                      },
                                      child: const Text('Approve'),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Linked guardians', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                        TextButton.icon(
                          onPressed: () => state.refreshLinkedGuardians(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    if (state.linkedGuardians.isEmpty)
                      const Text(
                        'No active guardians linked yet.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      )
                    else
                      ...state.linkedGuardians.map((g) {
                        final guardianId = (g['guardianId'] ?? '').toString();
                        final guardianName = (g['guardianName'] ?? 'Guardian').toString();
                        final guardianEmail = (g['guardianEmail'] ?? '').toString();
                        final raw = g['permissions'];
                        final permissions = raw is Map<String, dynamic>
                            ? {
                                'viewDocuments': raw['viewDocuments'] == true,
                                'viewMedicines': raw['viewMedicines'] == true,
                                'receiveEmergencyAlerts': raw['receiveEmergencyAlerts'] == true,
                                'manageMedicines': raw['manageMedicines'] == true,
                              }
                            : {
                                'viewDocuments': true,
                                'viewMedicines': true,
                                'receiveEmergencyAlerts': true,
                                'manageMedicines': false,
                              };

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(guardianName, style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                                if (guardianEmail.isNotEmpty)
                                  Text(guardianEmail, style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textSecondary)),
                                const SizedBox(height: 8),
                                _PermissionToggleRow(
                                  label: 'View Records',
                                  value: permissions['viewDocuments'] == true,
                                  onChanged: (v) => _updatePermission(
                                    context,
                                    guardianId,
                                    permissions,
                                    'viewDocuments',
                                    v,
                                  ),
                                ),
                                _PermissionToggleRow(
                                  label: 'View Medicines',
                                  value: permissions['viewMedicines'] == true,
                                  onChanged: (v) => _updatePermission(
                                    context,
                                    guardianId,
                                    permissions,
                                    'viewMedicines',
                                    v,
                                  ),
                                ),
                                _PermissionToggleRow(
                                  label: 'Manage Medicines',
                                  value: permissions['manageMedicines'] == true,
                                  onChanged: (v) => _updatePermission(
                                    context,
                                    guardianId,
                                    permissions,
                                    'manageMedicines',
                                    v,
                                  ),
                                ),
                                _PermissionToggleRow(
                                  label: 'Emergency Alerts',
                                  value: permissions['receiveEmergencyAlerts'] == true,
                                  onChanged: (v) => _updatePermission(
                                    context,
                                    guardianId,
                                    permissions,
                                    'receiveEmergencyAlerts',
                                    v,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: guardianId.isEmpty
                                        ? null
                                        : () => _confirmUnlinkGuardian(
                                              context,
                                              guardianId,
                                              guardianName,
                                            ),
                                    icon: const Icon(
                                      Icons.link_off_rounded,
                                      size: 16,
                                      color: AppTheme.danger,
                                    ),
                                    label: const Text(
                                      'Unlink Guardian',
                                      style: TextStyle(
                                        color: AppTheme.danger,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppTheme.danger,
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ] else ...[
                    Text(
                      state.linkedPatientProfile != null
                          ? 'Linked to patient: ${state.linkedPatientProfile!.name}'
                          : 'Not linked to any patient yet.',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showLinkPatientDialog(context),
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: Text(state.linkedPatientProfile == null
                            ? 'Enter Invite Code'
                            : 'Link Another Patient'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => state.refreshRoleContext(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Refresh Link Status'),
                      ),
                    ),
                    if ((state.guardianPairingStatusMessage ?? '').isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECF8F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFB6E2CA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 18, color: Color(0xFF2F855A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.guardianPairingStatusMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2F855A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (state.linkedPatientProfile != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your access', style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _permChip('Records', state.guardianPermissions['viewDocuments'] == true),
                                _permChip('Medicines', state.guardianPermissions['viewMedicines'] == true),
                                _permChip('Manage meds', state.guardianPermissions['manageMedicines'] == true),
                                _permChip('Alerts', state.guardianPermissions['receiveEmergencyAlerts'] == true),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ]),
              ),
            ),
          ),

          // Data controls
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Controls',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      value: state.crisisModeEnabled,
                      onChanged: (v) => state.setCrisisModeEnabled(v),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Crisis Mode'),
                      subtitle: const Text(
                        'High-contrast emergency UI with larger SOS controls.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Demo Reliability Panel',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                              TextButton(
                                onPressed: () => state.refreshReliabilityStatus(),
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...state.reliabilityStatus.entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _exportData(context),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Export My Data'),
                      ),
                    ),
                    if (state.isPatient) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDeleteHealthData(context),
                          icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.danger),
                          label: const Text(
                            'Delete My Health Data',
                            style: TextStyle(color: AppTheme.danger),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.danger, width: 1.2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Sign out
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await state.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false);
  }
},
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                  label: const Text('Sign Out', style: TextStyle(
                    color: AppTheme.danger, fontSize: 16, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.danger, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        Expanded(child: Text(value, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Add Emergency Contact'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: relationCtrl,
                  decoration: const InputDecoration(labelText: 'Relation'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final relation = relationCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty || relation.isEmpty || phone.isEmpty) return;

              await context.read<AppState>().addEmergencyContact(
                EmergencyContact(name: name, relation: relation, phone: phone),
              );

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLinkPatientDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Link Patient Account'),
        content: TextField(
          controller: codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            hintText: 'Enter 6-digit code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty || code.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 6-digit invite code.')),
                );
                return;
              }

              setStateDialog(() => isSubmitting = true);

              final error = await context.read<AppState>().requestPatientLink(code);
              if (!context.mounted) return;
              setStateDialog(() => isSubmitting = false);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Pair request sent. Ask patient to approve it.'),
                ),
              );
            },
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Request'),
          ),
        ],
      )),
    );
  }

  Future<void> _updatePermission(
    BuildContext context,
    String guardianId,
    Map<String, bool> current,
    String key,
    bool value,
  ) async {
    if (guardianId.isEmpty) return;
    final next = Map<String, bool>.from(current)..[key] = value;
    final ok = await context.read<AppState>().updateGuardianPermissions(
      guardianId: guardianId,
      permissions: next,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Permissions updated.' : 'Could not update permissions.')),
    );
  }

  Future<void> _confirmUnlinkGuardian(
    BuildContext context,
    String guardianId,
    String guardianName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unlink Guardian?'),
        content: Text('Remove $guardianName from your linked guardians?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Unlink', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<AppState>().unlinkGuardian(guardianId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Guardian unlinked successfully.' : 'Could not unlink guardian.')),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final filePath = await context.read<AppState>().exportDataToJsonFile();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(filePath == null
            ? 'Could not export data right now.'
            : 'Data exported successfully. File path: $filePath'),
      ),
    );
  }

  Future<void> _confirmDeleteHealthData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Health Data?'),
        content: const Text(
          'This will permanently remove your records, medicines, and emergency contacts. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<AppState>().deleteMyHealthData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Your health data has been deleted.' : 'Could not delete data right now.'),
      ),
    );
  }

  Widget _permChip(String label, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: enabled
            ? AppTheme.secondary.withValues(alpha: 0.12)
            : AppTheme.textHint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: enabled
              ? AppTheme.secondary.withValues(alpha: 0.3)
              : AppTheme.textHint.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: enabled ? AppTheme.secondary : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _PermissionToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.secondary,
            activeTrackColor: AppTheme.secondary.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
