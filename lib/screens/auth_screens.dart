import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import 'main_shell.dart';
import 'terms_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: size.height * 0.35,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppTheme.primaryDark, AppTheme.primary, Color(0xFF2196F3)]),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40))),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4), width: 2)),
                        child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 44),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 14),
                      const Text('HealthVault', style: TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Where your health is never forgotten',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20)),
                        child: const Text('Team Tesla · PES University',
                          style: TextStyle(color: Colors.white, fontSize: 11))),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back 👋', style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('Sign in to your health vault', style: TextStyle(
                        fontSize: 15, color: AppTheme.textSecondary)),
                      const SizedBox(height: 28),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          hintText: 'your@email.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary)),
                        validator: (v) => v!.isEmpty ? 'Please enter email' : null,
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textHint),
                            onPressed: () => setState(() => _obscure = !_obscure))),
                        validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                        onFieldSubmitted: (_) => _handleLogin(),
                      ).animate().fadeIn(delay: 150.ms),

                      const SizedBox(height: 8),

                      if (state.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12)),
                          child: Text(state.error!,
                            style: const TextStyle(color: AppTheme.danger, fontSize: 14))),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity, height: 58,
                        child: ElevatedButton.icon(
                          onPressed: state.isLoading ? null : _handleLogin,
                          icon: state.isLoading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.login_rounded, color: Colors.white),
                          label: Text(state.isLoading ? 'Signing in...' : 'Sign In',
                            style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity, height: 58,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SignupScreen())),
                          icon: const Icon(Icons.person_add_outlined),
                          label: const Text('Create New Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AppState>().clearError();
    final ok = await context.read<AppState>().signIn(
      _emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
    }
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  String _accountType = 'patient';
  bool _obscure = true;
  int _step = 0;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose();
    _ageCtrl.dispose(); _bloodCtrl.dispose();
    _conditionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => _step > 0
            ? setState(() => _step--) : Navigator.pop(context)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(3, (i) => Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _step ? AppTheme.primary : AppTheme.divider,
                        borderRadius: BorderRadius.circular(3))))),
                ),
                const SizedBox(height: 28),
                if (_step == 0) _buildAccountTypeStep(),
                if (_step == 1) _buildPersonalInfoStep(),
                if (_step == 2) _buildSecurityStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Who are you?', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Choose your account type', style: TextStyle(
          fontSize: 15, color: AppTheme.textSecondary)),
        const SizedBox(height: 32),
        _AccountTypeCard(
          icon: Icons.elderly_rounded, title: 'Patient',
          subtitle: 'I am a patient managing my health records',
          selected: _accountType == 'patient',
          onTap: () => setState(() => _accountType = 'patient')),
        const SizedBox(height: 16),
        _AccountTypeCard(
          icon: Icons.family_restroom_rounded, title: 'Guardian / Family',
          subtitle: 'I am monitoring a family member\'s health',
          selected: _accountType == 'guardian',
          onTap: () => setState(() => _accountType = 'guardian')),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity, height: 58,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _step = 1),
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            label: const Text('Continue',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your details', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Tell us about yourself', style: TextStyle(
          fontSize: 15, color: AppTheme.textSecondary)),
        const SizedBox(height: 28),
        TextFormField(
          controller: _nameCtrl,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            labelText: 'Full name *', hintText: 'e.g. Rajesh Kumar',
            prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary)),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            labelText: 'Mobile number *', hintText: '+91 98765 43210',
            prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary)),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        if (_accountType == 'patient') ...[
          TextFormField(
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Age', hintText: '68',
              prefixIcon: Icon(Icons.cake_outlined, color: AppTheme.primary)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _bloodCtrl,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Blood Group', hintText: 'e.g. B+',
              prefixIcon: Icon(Icons.bloodtype_rounded, color: AppTheme.primary)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _conditionsCtrl,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Health Conditions (optional)',
              hintText: 'e.g. Diabetes, Hypertension',
              prefixIcon: Icon(Icons.medical_information_rounded,
                color: AppTheme.primary)),
          ),
          const SizedBox(height: 14),
        ],
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            labelText: 'Email address *', hintText: 'your@email.com',
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary)),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 58,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_formKey.currentState!.validate()) setState(() => _step = 2);
            },
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            label: const Text('Continue',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSecurityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Secure your account', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 28),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textHint),
              onPressed: () => setState(() => _obscure = !_obscure))),
          validator: (v) => v!.length < 6 ? 'At least 6 characters' : null,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('⚕️ Medical Disclaimer', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            const Text(
              'AI-generated summaries are NOT medical diagnoses. '
              'Always consult a qualified doctor before making medical decisions.',
              style: TextStyle(fontSize: 13, height: 1.5,
                color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TermsScreen())),
              child: const Text('Read full Terms & Conditions →',
                style: TextStyle(color: AppTheme.primary,
                  fontWeight: FontWeight.w600, fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity, height: 58,
          child: ElevatedButton.icon(
            onPressed: context.watch<AppState>().isLoading ? null : _handleSignup,
            icon: context.watch<AppState>().isLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text('Create Account & Accept Terms',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final conditions = _conditionsCtrl.text.trim().isEmpty
      ? <String>[]
      : _conditionsCtrl.text.split(',').map((e) => e.trim()).toList();
    final ok = await context.read<AppState>().signUp(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim(),
      accountType: _accountType,
      age: int.tryParse(_ageCtrl.text),
      bloodGroup: _bloodCtrl.text.trim(),
      conditions: conditions,
    );
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
    }
  }
}

class _AccountTypeCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _AccountTypeCard({required this.icon, required this.title,
    required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
            width: selected ? 2.5 : 1)),
        child: Row(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16)),
            child: Icon(icon,
              color: selected ? Colors.white : AppTheme.primary, size: 30)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: selected ? AppTheme.primary : AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13,
              color: AppTheme.textSecondary, height: 1.4)),
          ])),
          if (selected) const Icon(Icons.check_circle_rounded,
            color: AppTheme.primary, size: 26),
        ]),
      ),
    );
  }
}