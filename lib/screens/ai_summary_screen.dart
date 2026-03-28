import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/ai_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AISummaryScreen extends StatefulWidget {
  final Map<String, dynamic> doc;
  const AISummaryScreen({super.key, required this.doc});
  @override State<AISummaryScreen> createState() => _AISummaryScreenState();
}

class _AISummaryScreenState extends State<AISummaryScreen> {
  String _selectedLanguage = 'English';
  String? _summary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load existing AI summary if available
    final existing = widget.doc['aiSummary'];
    if (existing != null && existing.toString().isNotEmpty) {
      _summary = existing.toString();
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Lab Report': return Icons.science_rounded;
      case 'Prescription': return Icons.receipt_long_rounded;
      case 'Scan / X-Ray': return Icons.monitor_heart_rounded;
      case 'Discharge Summary': return Icons.summarize_rounded;
      case 'Medical Bill': return Icons.receipt_rounded;
      default: return Icons.folder_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'Lab Report': return const Color(0xFF3498DB);
      case 'Prescription': return const Color(0xFF2ECC71);
      case 'Scan / X-Ray': return const Color(0xFF9B59B6);
      case 'Discharge Summary': return const Color(0xFF1ABC9C);
      case 'Medical Bill': return const Color(0xFFF39C12);
      default: return const Color(0xFF95A5A6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final docType = doc['type']?.toString() ?? doc['documentType']?.toString() ?? 'Document';
    final color = _colorForType(docType);
    final icon = _iconForType(docType);
    final name = doc['name']?.toString() ?? 'Document';
    final hospital = doc['hospital']?.toString() ?? doc['hospitalName']?.toString() ?? '';
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('AI Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareSummary),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Document info card
            HealthCard(
              child: Row(children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color, size: 32)),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(hospital, style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6)),
                      child: Text(docType, style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: color))),
                  ])),
              ]),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            // Language selector
            const Text('Language', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['English', 'Hindi', 'Telugu', 'Kannada', 'Tamil']
                  .map((lang) {
                    final sel = lang == _selectedLanguage;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedLanguage = lang;
                          _summary = null;
                        }),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? AppTheme.primary : AppTheme.divider)),
                          child: Text(lang, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppTheme.textSecondary)),
                        ),
                      ),
                    );
                  }).toList(),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),
            const DisclaimerBox(text: AppConstants.medicalDisclaimer),

            const SizedBox(height: 20),

            // Generate button
            if (_summary == null)
              BigButton(
                label: _isLoading
                  ? 'AI is reading your report...'
                  : 'Generate AI Explanation',
                icon: Icons.auto_awesome_rounded,
                isLoading: _isLoading,
                onTap: _generateSummary,
              ).animate().fadeIn(delay: 150.ms),

            // Summary content
            if (_summary != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Row(children: [
                          Icon(Icons.auto_awesome_rounded,
                            color: AppTheme.primary, size: 16),
                          SizedBox(width: 6),
                          Text('AI Explanation', style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                        ])),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10)),
                        child: Text(_selectedLanguage, style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppTheme.secondary))),
                    ]),
                    const SizedBox(height: 16),
                    Text(_summary!, style: const TextStyle(
                      fontSize: 16, height: 1.8,
                      color: AppTheme.textPrimary)),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _summary = null);
                    _generateSummary();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Regenerate'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppTheme.divider),
                    foregroundColor: AppTheme.textSecondary),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  onPressed: _shareSummary,
                  icon: const Icon(Icons.share_rounded,
                    size: 18, color: Colors.white),
                  label: const Text('Share',
                    style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: AppTheme.primary),
                )),
              ]),

              const SizedBox(height: 8),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSummary() async {
    setState(() { _isLoading = true; _summary = null; });
    try {
      final user = context.read<AppState>().currentUser;
      final doc = widget.doc;
      final docType = doc['type']?.toString()
        ?? doc['documentType']?.toString() ?? 'Medical Document';
      final name = doc['name']?.toString() ?? 'Document';
      final hospital = doc['hospital']?.toString()
        ?? doc['hospitalName']?.toString() ?? '';
      final notes = doc['notes']?.toString() ?? '';

      // Build document text from available info
      final documentText = '''
Document Name: $name
Document Type: $docType
Hospital: $hospital
Notes: ${notes.isEmpty ? 'None' : notes}
${doc['aiSummary'] != null ? 'Previous Summary: ${doc['aiSummary']}' : ''}
''';

      final summary = await AIService.generateDocumentSummary(
        documentText: documentText,
        documentType: docType,
        language: _selectedLanguage,
        patientName: user?.name ?? 'Patient',
      );

      // Save summary to AppState
      final docId = doc['id']?.toString();
      if (docId != null && mounted) {
        await context.read<AppState>()
          .updateDocumentSummary(docId, summary, _selectedLanguage);
      }

      if (mounted) setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _summary = 'Error generating summary: $e\n\nPlease try again.';
      });
    }
  }

  void _shareSummary() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary copied to clipboard'),
        backgroundColor: AppTheme.secondary));
  }
}