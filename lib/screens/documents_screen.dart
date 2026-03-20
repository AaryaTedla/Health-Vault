import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import 'upload_document_screen.dart';
import 'ai_summary_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';
  String _query = '';

  final List<String> _filters = [
    'All', 'Prescription', 'Lab Report', 'Scan / X-Ray',
    'Discharge Summary', 'Medical Bill', 'Other'
  ];

  List<HealthDocument> _filtered(List<HealthDocument> docs) {
    return docs.where((d) {
      final matchesFilter = _selectedFilter == 'All'
        || d.documentType == _selectedFilter;
      final matchesQuery = _query.isEmpty
        || d.name.toLowerCase().contains(_query.toLowerCase())
        || d.hospitalName.toLowerCase().contains(_query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();
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
    final docs = context.watch<AppState>().documents;
    final filtered = _filtered(docs);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: 'Health Records',
              subtitle: '${docs.length} documents stored securely',
              height: 120,
              actions: [
                IconButton(
                  icon: const Icon(Icons.sort_rounded, color: Colors.white),
                  onPressed: _showSortOptions),
              ],
            ),
          ),

          // Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search by name, hospital...',
                  prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.primary),
                  suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        }) : null,
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.divider)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.divider)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ).animate().fadeIn(delay: 100.ms),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filters.length,
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final selected = f == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                              ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                ? AppTheme.primary : AppTheme.divider)),
                          child: Text(f, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: selected
                              ? Colors.white : AppTheme.textSecondary)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Document list
          filtered.isEmpty
            ? SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.folder_open_rounded,
                  title: docs.isEmpty
                    ? 'No documents yet'
                    : 'No documents found',
                  subtitle: docs.isEmpty
                    ? 'Upload your first health document to get started.'
                    : 'Try a different search or filter.',
                  buttonLabel: 'Upload Document',
                  onButton: () => Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => const UploadDocumentScreen())),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final doc = filtered[i];
                    return _DocumentCard(
                      doc: doc,
                      index: i,
                      icon: _iconForType(doc.documentType),
                      color: _colorForType(doc.documentType),
                      onViewSummary: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => AISummaryScreen(
                            doc: {
                              'id': doc.id,
                              'name': doc.name,
                              'hospital': doc.hospitalName,
                              'type': doc.documentType,
                              'fileUrl': doc.fileUrl,
                              'fileType': doc.fileType,
                              'aiSummary': doc.aiSummary,
                              'notes': doc.notes,
                            }))),
                      onDelete: () => _confirmDelete(context, doc),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const UploadDocumentScreen())),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Upload', style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, HealthDocument doc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to delete "${doc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteDocument(doc.id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
              style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Sort by', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...[
            ['Date (newest)', Icons.calendar_today_rounded],
            ['Date (oldest)', Icons.calendar_month_rounded],
            ['Name (A-Z)', Icons.sort_by_alpha_rounded],
            ['Hospital', Icons.local_hospital_rounded],
          ].map((s) => ListTile(
            leading: Icon(s[1] as IconData, color: AppTheme.primary),
            title: Text(s[0] as String,
              style: const TextStyle(fontSize: 15)),
            onTap: () => Navigator.pop(context),
          )),
        ]),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final HealthDocument doc;
  final int index;
  final IconData icon;
  final Color color;
  final VoidCallback onViewSummary;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.doc, required this.index,
    required this.icon, required this.color,
    required this.onViewSummary, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = doc.fileType == 'image';
    final fileExists = File(doc.fileUrl).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: HealthCard(
        onTap: onViewSummary,
        child: Column(children: [
          Row(children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.name, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(doc.hospitalName, style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                    size: 12, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${doc.uploadedAt.day}/${doc.uploadedAt.month}/${doc.uploadedAt.year}',
                    style: const TextStyle(
                      fontSize: 12, color: AppTheme.textHint)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(doc.documentType, style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: color))),
                ]),
              ],
            )),
            Column(children: [
              Icon(
                isImage
                  ? Icons.image_rounded
                  : Icons.picture_as_pdf_rounded,
                color: AppTheme.textHint, size: 20),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.danger, size: 20)),
            ]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            if (fileExists) ...[
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _openFile(context),
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text('View', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: AppTheme.divider),
                  foregroundColor: AppTheme.textSecondary),
              )),
              const SizedBox(width: 8),
            ],
            Expanded(child: ElevatedButton.icon(
              onPressed: onViewSummary,
              icon: const Icon(Icons.auto_awesome_rounded,
                size: 16, color: Colors.white),
              label: Text(
                doc.aiSummary != null ? 'AI Summary' : 'Generate AI',
                style: const TextStyle(
                  fontSize: 13, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: AppTheme.primary),
            )),
          ]),
        ]),
      ).animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index))
        .slideY(begin: 0.05),
    );
  }

  void _openFile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File saved at: ${doc.fileUrl}')));
  }
}