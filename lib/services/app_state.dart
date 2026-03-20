import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';

class AppState extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  String _selectedLanguage = 'English';
  List<HealthDocument> _documents = [];
  List<MedicineReminder> _medicines = [];

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedLanguage => _selectedLanguage;
  bool get isLoggedIn => _currentUser != null;
  bool get isPatient => _currentUser?.isPatient ?? false;
  bool get isGuardian => _currentUser?.isGuardian ?? false;
  List<HealthDocument> get documents => _documents;
  List<MedicineReminder> get medicines => _medicines;

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    if (email.isNotEmpty && password.length >= 6) {
      _currentUser = AppUser(
        uid: 'user_${email.hashCode}',
        name: email.split('@').first,
        email: email,
        phone: '',
        accountType: 'patient',
        language: 'English',
        createdAt: DateTime.now(),
        conditions: [],
        emergencyContacts: [],
      );
      await _loadDocuments();
      await _loadMedicines();
      _setLoading(false);
      return true;
    }
    _error = 'Invalid credentials';
    _setLoading(false);
    return false;
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String accountType,
    int? age,
    String? bloodGroup,
    List<String> conditions = const [],
  }) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      accountType: accountType,
      language: 'English',
      createdAt: DateTime.now(),
      age: age,
      bloodGroup: bloodGroup,
      conditions: conditions,
      emergencyContacts: [],
    );
    await _loadDocuments();
    await _loadMedicines();
    _setLoading(false);
    return true;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _documents = [];
    _medicines = [];
    notifyListeners();
  }

  // ─── Documents ──────────────────────────────────────────────────

  Future<void> _loadDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _currentUser?.uid ?? 'demo_001';
      final jsonStr = prefs.getString('documents_$uid');
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _documents = jsonList.map((e) => HealthDocument.fromMap(e)).toList();
        _documents.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      }
    } catch (e) {
      print('Error loading documents: $e');
    }
    notifyListeners();
  }

  Future<void> _saveDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _currentUser?.uid ?? 'demo_001';
      final jsonStr = jsonEncode(_documents.map((d) => d.toMap()).toList());
      await prefs.setString('documents_$uid', jsonStr);
    } catch (e) {
      print('Error saving documents: $e');
    }
  }

  Future<String> copyFileToAppStorage(File sourceFile, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/health_documents');
      if (!await docsDir.exists()) await docsDir.create(recursive: true);
      final ext = path.extension(fileName);
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = '${docsDir.path}/$uniqueName';
      await sourceFile.copy(destPath);
      return destPath;
    } catch (e) {
      print('Error copying file: $e');
      return sourceFile.path;
    }
  }

  Future<void> addDocument(HealthDocument doc) async {
    _documents.insert(0, doc);
    await _saveDocuments();
    notifyListeners();
  }

  Future<void> updateDocumentSummary(
      String docId, String summary, String language) async {
    final idx = _documents.indexWhere((d) => d.id == docId);
    if (idx == -1) return;
    final doc = _documents[idx];
    final updated = HealthDocument(
      id: doc.id, patientId: doc.patientId, name: doc.name,
      hospitalName: doc.hospitalName, documentType: doc.documentType,
      fileUrl: doc.fileUrl, fileType: doc.fileType, notes: doc.notes,
      aiSummary: language == 'English' ? summary : doc.aiSummary,
      aiSummaryHindi: language == 'Hindi' ? summary : doc.aiSummaryHindi,
      aiSummaryTelugu: language == 'Telugu' ? summary : doc.aiSummaryTelugu,
      aiSummaryKannada: language == 'Kannada' ? summary : doc.aiSummaryKannada,
      aiSummaryTamil: language == 'Tamil' ? summary : doc.aiSummaryTamil,
      uploadedAt: doc.uploadedAt, fileSize: doc.fileSize);
    _documents[idx] = updated;
    await _saveDocuments();
    notifyListeners();
  }

  Future<void> deleteDocument(String docId) async {
    _documents.removeWhere((d) => d.id == docId);
    await _saveDocuments();
    notifyListeners();
  }

  // ─── Medicines ───────────────────────────────────────────────────

  Future<void> _loadMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _currentUser?.uid ?? 'demo_001';
      final jsonStr = prefs.getString('medicines_$uid');
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _medicines = jsonList.map((e) => MedicineReminder.fromMap(e)).toList();
      }
    } catch (e) {
      print('Error loading medicines: $e');
    }
    notifyListeners();
  }

  Future<void> _saveMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _currentUser?.uid ?? 'demo_001';
      final jsonStr = jsonEncode(_medicines.map((m) => m.toMap()).toList());
      await prefs.setString('medicines_$uid', jsonStr);
    } catch (e) {
      print('Error saving medicines: $e');
    }
  }

  Future<void> addMedicine(MedicineReminder med) async {
    _medicines.add(med);
    await _saveMedicines();
    notifyListeners();
  }

  Future<void> deleteMedicine(String medId) async {
    _medicines.removeWhere((m) => m.id == medId);
    await _saveMedicines();
    notifyListeners();
  }

  // ─── Utils ───────────────────────────────────────────────────────

  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}