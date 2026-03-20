import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import 'dashboard_screen.dart';
import 'documents_screen.dart';
import 'medicine_screen.dart';
import 'ai_chat_screen.dart';
import 'auth_screens.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    DocumentsScreen(),
    MedicineScreen(),
    AIChatScreen(),
    _ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
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
                _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: _currentIndex, onTap: _setTab),
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
          if (user?.emergencyContacts.isNotEmpty ?? false)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.divider)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Emergency Contacts', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
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
                        const Icon(Icons.call_rounded, color: AppTheme.secondary, size: 22),
                      ]),
                    )),
                  ]),
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
}
