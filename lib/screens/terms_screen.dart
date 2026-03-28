import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HealthVault', style: TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('Terms of Service & Privacy Policy', style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ─── MANDATORY MEDICAL DISCLAIMER ────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_information_rounded, color: AppTheme.danger),
                      const SizedBox(width: 10),
                      const Text('⚕️ Medical Disclaimer (Mandatory)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppTheme.danger)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AI-generated summaries, explanations, and voice responses provided by '
                    'HealthVault are NOT medical diagnoses, medical advice, or a substitute '
                    'for professional medical consultation.\n\n'
                    'You MUST consult a qualified, licensed doctor or healthcare professional '
                    'before making any medical decisions, changing medications, or acting on '
                    'information provided by this application.\n\n'
                    'HealthVault is an information and organization tool only.',
                    style: TextStyle(fontSize: 14, height: 1.7, color: AppTheme.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection('1. Data Privacy & Security',
              'Your health data is encrypted and stored securely. '
              'Only you and linked guardians can access your records. '
              'We comply with applicable data protection regulations including '
              'the Digital Personal Data Protection (DPDP) Act, 2023 (India).'
              '\n\nYour data is never sold to third parties.'),

            _buildSection('2. AI Features',
              'This app uses artificial intelligence to:\n'
              '• Summarize medical documents in simple language\n'
              '• Answer general health questions\n'
              '• Explain symptoms and medicines\n\n'
              'All AI responses include a mandatory disclaimer. '
              'AI accuracy is not guaranteed. Always verify with a doctor.'),

            _buildSection('3. Guardian Access',
              'If you link a guardian, they will have read-only access to your '
              'health records, AI summaries, and medicine reminder status. '
              'You can unlink a guardian at any time from Settings.'),

            _buildSection('4. Emergency Contacts',
              'Emergency alert features send notifications to contacts you have '
              'explicitly added. You are responsible for obtaining consent from '
              'contacts before adding them.'),

            _buildSection('5. Medicine Reminders',
              'Medicine reminders are provided as a convenience tool only. '
              'We are not responsible for missed doses or medication errors. '
              'Always verify your medication schedule with your doctor or pharmacist.'),

            _buildSection('6. Document Storage',
              'Uploaded documents are stored in encrypted cloud storage. '
              'HealthVault does not share your documents with any third parties '
              'without your explicit consent. You can delete your data at any time.'),

            _buildSection('7. Limitation of Liability',
              'Team Tesla and HealthVault are not liable for any medical decisions '
              'made based on information from this application. This app is a prototype '
              'developed for educational purposes under PES University CIE.'),

            const SizedBox(height: 24),
            BigButton(
              label: 'I Understand & Accept',
              icon: Icons.check_circle_outline,
              onTap: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Last updated: January 2025',
                style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
            ),
            const SizedBox(height: 24),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(
            fontSize: 14, color: AppTheme.textSecondary, height: 1.7)),
          const SizedBox(height: 8),
          const Divider(color: AppTheme.divider),
        ],
      ),
    );
  }
}
