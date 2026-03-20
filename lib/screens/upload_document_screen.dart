import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_theme.dart';
import '../services/app_state.dart';
import '../services/ai_service.dart';
import '../services/document_text_extractor.dart';
import '../models/models.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});
  @override State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _docType = 'Lab Report';
  File? _selectedFile;
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  String? _fileExtension;
  int? _fileSize;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _generateAI = true;
  String? _extractionStatus;
  bool _extractionSucceeded = false;
  String? _previewExtractedText;
  bool _isPreviewLoading = false;

  final List<String> _docTypes = [
    'Lab Report', 'Prescription', 'Scan / X-Ray',
    'Discharge Summary', 'Medical Bill', 'Other'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hospitalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        File? file;
        Uint8List? bytes;

        if (!kIsWeb) {
          final filePath = pickedFile.path;
          if (filePath != null) {
            file = File(filePath);
          }
        }

        if (file == null && pickedFile.bytes != null) {
          bytes = pickedFile.bytes;
        }

        if (file == null && bytes != null && !kIsWeb) {
          final tmpDir = await getTemporaryDirectory();
          final tmpPath = path.join(tmpDir.path, pickedFile.name);
          file = await File(tmpPath).writeAsBytes(bytes, flush: true);
        }

        if (file == null && bytes == null) {
          _showError('Could not access selected file. Please try another file.');
          return;
        }

        final fileName = pickedFile.name;
        final ext = path.extension(fileName).toLowerCase().replaceAll('.', '');
        final size = file != null ? await file.length() : (bytes?.length ?? 0);
        setState(() {
          _selectedFile = file;
          _selectedBytes = bytes;
          _selectedFileName = fileName;
          _fileExtension = ext;
          _fileSize = size;
          _extractionStatus = null;
          _extractionSucceeded = false;
          _previewExtractedText = null;
        });
        if (_nameCtrl.text.isEmpty) {
          _nameCtrl.text = path.basenameWithoutExtension(fileName)
            .replaceAll('_', ' ').replaceAll('-', ' ').trim();
        }
      }
    } catch (e) {
      _showError('HV_PICKER_ERR: Could not open file picker: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.danger));
  }

  Future<void> _previewExtractedTextForSelectedFile() async {
    final file = _selectedFile;
    final ext = _fileExtension;
    if (ext == null) return;

    if (kIsWeb && file == null) {
      setState(() {
        _previewExtractedText =
            'Preview is currently available on mobile/desktop builds. On web, upload still works with document details.';
      });
      return;
    }

    if (file == null) return;

    setState(() {
      _isPreviewLoading = true;
    });

    try {
      final text = await DocumentTextExtractor.extractTextFromFile(
        filePath: file.path,
        fileExtension: ext,
      );

      if (!mounted) return;
      setState(() {
        _previewExtractedText = (text == null || text.trim().isEmpty)
            ? 'No text could be extracted from this file.'
            : text.trim();
        _isPreviewLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewExtractedText = 'Failed to extract text from this file.';
        _isPreviewLoading = false;
      });
    }
  }

  Future<void> _handleUpload() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null && _selectedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a file to upload first'),
        backgroundColor: AppTheme.warning));
      return;
    }

    setState(() { _isUploading = true; _uploadProgress = 0; });

    try {
      final appState = context.read<AppState>();
      final user = appState.currentUser;

      // Step 1 — Copy file to app storage
      setState(() => _uploadProgress = 0.2);
      String savedPath;
      if (_selectedFile != null) {
        savedPath = await appState.copyFileToAppStorage(
          _selectedFile!,
          _selectedFileName!,
        );
      } else {
        final ext = _fileExtension ?? 'bin';
        savedPath = 'web_upload_${DateTime.now().millisecondsSinceEpoch}.$ext';
      }
      setState(() => _uploadProgress = 0.5);

      // Step 2 — Generate AI summary if enabled
      String? aiSummary;
      if (_generateAI) {
        setState(() => _uploadProgress = 0.7);
        setState(() {
          _extractionStatus = 'Extracting report text for better AI summary...';
          _extractionSucceeded = false;
        });
        String? extractedText;
        if (_selectedFile != null) {
          extractedText = await DocumentTextExtractor.extractTextFromFile(
            filePath: savedPath,
            fileExtension: _fileExtension ?? '',
          );
        }
        setState(() {
          _extractionSucceeded = extractedText != null && extractedText.trim().isNotEmpty;
          _extractionStatus = _extractionSucceeded
              ? 'Text extracted successfully. AI summary is using report content.'
              : 'Could not extract text from this file. AI will use document details and notes.';
        });
        final cappedExtractedText = (extractedText == null || extractedText.isEmpty)
            ? 'No extracted text available.'
            : extractedText.substring(
                0,
                extractedText.length > 4000 ? 4000 : extractedText.length,
              );

        aiSummary = await AIService.generateDocumentSummary(
          documentText: 'Document: ${_nameCtrl.text}, Type: $_docType, '
              'Hospital: ${_hospitalCtrl.text}. '
              'Notes: ${_notesCtrl.text.isEmpty ? "None" : _notesCtrl.text}\n\n'
              'Extracted Report Text:\n$cappedExtractedText',
          documentType: _docType,
          language: appState.selectedLanguage,
          patientName: user?.name ?? 'Patient',
        );
      }

      setState(() => _uploadProgress = 0.9);

      // Step 3 — Save document to local storage
      final doc = HealthDocument(
        id: const Uuid().v4(),
        patientId: user?.uid ?? 'demo_001',
        name: _nameCtrl.text.trim(),
        hospitalName: _hospitalCtrl.text.trim(),
        documentType: _docType,
        fileUrl: savedPath,
        fileType: _fileExtension == 'pdf' ? 'pdf' : 'image',
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        aiSummary: aiSummary,
        uploadedAt: DateTime.now(),
        fileSize: (_fileSize ?? 0) / (1024 * 1024),
      );

      await appState.addDocument(doc);
      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        setState(() => _isUploading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showError('Upload failed: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8F0), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
              color: AppTheme.secondary, size: 44)),
          const SizedBox(height: 20),
          const Text('Upload Successful! 🎉',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('"${_nameCtrl.text}" saved securely.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          if (_generateAI) ...[
            const SizedBox(height: 8),
            const Text('AI summary has been generated!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.primary,
                fontSize: 13, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Back to Records',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = _fileExtension == 'pdf';
    final isImage = ['jpg', 'jpeg', 'png'].contains(_fileExtension);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Upload Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                GestureDetector(
                  onTap: _pickFile,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: _selectedFile != null ? 140 : 160,
                    decoration: BoxDecoration(
                      color: _selectedFile != null
                        ? AppTheme.primary.withValues(alpha: 0.04) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedFile != null
                          ? AppTheme.primary : AppTheme.divider,
                        width: _selectedFile != null ? 2 : 1.5)),
                    child: _selectedFile == null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle),
                            child: const Icon(Icons.cloud_upload_rounded,
                              color: AppTheme.primary, size: 34)),
                          const SizedBox(height: 14),
                          const Text('Tap to select file from your phone',
                            style: TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w700, color: AppTheme.primary)),
                          const SizedBox(height: 4),
                          const Text('PDF, JPG, PNG supported',
                            style: TextStyle(fontSize: 13,
                              color: AppTheme.textSecondary)),
                        ])
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                color: isPdf
                                  ? AppTheme.danger.withValues(alpha: 0.1)
                                  : AppTheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14)),
                              child: Icon(
                                isPdf
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.image_rounded,
                                color: isPdf ? AppTheme.danger : AppTheme.primary,
                                size: 32)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_selectedFileName ?? '',
                                  style: const TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w700),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      _fileExtension?.toUpperCase() ?? '',
                                      style: const TextStyle(fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.secondary))),
                                  const SizedBox(width: 8),
                                  if (_fileSize != null)
                                    Text(_formatBytes(_fileSize!),
                                      style: const TextStyle(fontSize: 12,
                                        color: AppTheme.textHint)),
                                ]),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: _pickFile,
                                  child: const Text('Change file',
                                    style: TextStyle(fontSize: 12,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600))),
                              ],
                            )),
                            const Icon(Icons.check_circle_rounded,
                              color: AppTheme.secondary, size: 28),
                          ]),
                        ),
                  ),
                ).animate().fadeIn(duration: 300.ms),

                if (_selectedFile != null && isImage) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: kIsWeb && _selectedBytes != null
                        ? Image.memory(
                            _selectedBytes!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          )
                        : Image.file(
                            _selectedFile!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                  ),
                ],

                if (_selectedFile != null && _generateAI) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isPreviewLoading ? null : _previewExtractedTextForSelectedFile,
                      icon: _isPreviewLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.find_in_page_rounded, size: 18),
                      label: Text(
                        _isPreviewLoading
                            ? 'Extracting text...'
                            : 'Preview extracted text',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],

                if (_previewExtractedText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _previewExtractedText!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                const Text('Document Type',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _docTypes.map((t) => GestureDetector(
                    onTap: () => setState(() => _docType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _docType == t ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _docType == t ? AppTheme.primary : AppTheme.divider)),
                      child: Text(t, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: _docType == t ? Colors.white : AppTheme.textSecondary)),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Document name *',
                    hintText: 'e.g. Blood Sugar Test Jan 2025',
                    prefixIcon: Icon(Icons.description_outlined,
                      color: AppTheme.primary)),
                  validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _hospitalCtrl,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Hospital / Clinic name *',
                    hintText: 'e.g. Apollo Hospital, Bangalore',
                    prefixIcon: Icon(Icons.local_hospital_outlined,
                      color: AppTheme.primary)),
                  validator: (v) => v!.isEmpty ? 'Please enter hospital name' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Any additional notes about this document...',
                    prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.primary),
                    alignLabelWithHint: true),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2))),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.primary, size: 26),
                    const SizedBox(width: 14),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generate AI Summary',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('AI will explain this document in simple language',
                          style: TextStyle(fontSize: 12,
                            color: AppTheme.textSecondary)),
                      ])),
                    Switch(
                      value: _generateAI,
                      onChanged: (v) => setState(() => _generateAI = v),
                      activeThumbColor: AppTheme.primary),
                  ]),
                ),

                if (_extractionStatus != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_extractionSucceeded ? AppTheme.secondary : AppTheme.warning)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_extractionSucceeded ? AppTheme.secondary : AppTheme.warning)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _extractionSucceeded ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 18,
                          color: _extractionSucceeded ? AppTheme.secondary : AppTheme.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _extractionStatus!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                if (_isUploading) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      _uploadProgress < 0.5 ? 'Saving file...'
                      : _uploadProgress < 0.8 ? 'Generating AI summary...'
                      : 'Finishing up...',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: AppTheme.divider,
                      color: AppTheme.primary, minHeight: 8)),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity, height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _handleUpload,
                    icon: _isUploading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.upload_rounded,
                          color: Colors.white, size: 22),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Upload & Save Document',
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.25))),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_rounded,
                        color: AppTheme.secondary, size: 18),
                      SizedBox(width: 10),
                      Expanded(child: Text(
                        'Your documents are stored locally on your device. Only you and linked guardians can access them.',
                        style: TextStyle(fontSize: 13,
                          color: AppTheme.textSecondary, height: 1.5))),
                    ]),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}