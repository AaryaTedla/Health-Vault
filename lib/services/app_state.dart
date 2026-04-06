import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';
import 'audit_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier {
  static const String _currentUidKey = 'current_uid';
  static const String _crisisModeKey = 'crisis_mode_enabled';

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  String _selectedLanguage = 'English';
  List<HealthDocument> _documents = [];
  List<MedicineReminder> _medicines = [];
  List<Appointment> _appointments = [];
  String? _activePairingCode;
  List<Map<String, dynamic>> _pendingPairingRequests = [];
  String? _linkedPatientId;
  AppUser? _linkedPatientProfile;
  Map<String, bool> _guardianPermissions = {
    'viewDocuments': true,
    'viewMedicines': true,
    'receiveEmergencyAlerts': true,
    'manageMedicines': false,
  };
  List<Map<String, dynamic>> _linkedGuardians = [];

  bool _isLiveLocationSharing = false;
  DateTime? _liveLocationExpiresAt;
  Map<String, dynamic>? _liveLocationSnapshot;
  Timer? _liveLocationUpdateTimer;
  Timer? _liveLocationExpiryTimer;
  Timer? _guardianLiveLocationPollTimer;
  Timer? _guardianLinkSyncTimer;
  bool _isPushingLiveLocation = false;
  bool _isRefreshingLiveLocationSnapshot = false;
  bool _isGuardianLinkSyncRunning = false;
  bool _isSyncingRoleContext = false;
  bool _shouldStopWarmup = false; // Warmup cancellation token
  String? _liveLocationStatusNote;
  DateTime? _lastGuardianNotifiedLiveExpiry;
  bool _crisisModeEnabled = false;
  List<Map<String, dynamic>> _guardianEmergencyResponses = [];
  Map<String, String> _reliabilityStatus = const {};
  StreamSubscription<User?>? _authStateSubscription;

  AppState() {
    _restoreSession();
    _setupAuthStateListener(); // Listen to Firebase auth changes
  }

  void _setupAuthStateListener() {
    // Listen to Firebase Auth state changes to handle persistent login/logout
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? firebaseUser) {
        if (firebaseUser == null && _currentUser != null) {
          // User logged out - clear local session
          _currentUser = null;
          notifyListeners();
        } else if (firebaseUser != null && _currentUser == null) {
          // User logged in externally - restore their profile
          _restoreSession();
        }
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _cancelAllBackgroundTimers();
    super.dispose();
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedLanguage => _selectedLanguage;
  bool get isLoggedIn => _currentUser != null;
  bool get isPatient => _currentUser?.isPatient ?? false;
  bool get isGuardian => _currentUser?.isGuardian ?? false;
  List<HealthDocument> get documents => _documents;
  List<MedicineReminder> get medicines => _medicines;
  List<Appointment> get appointments => _appointments;
  String? get activePairingCode => _activePairingCode;
  List<Map<String, dynamic>> get pendingPairingRequests =>
      _pendingPairingRequests;
  String? get linkedPatientId => _linkedPatientId;
  AppUser? get linkedPatientProfile => _linkedPatientProfile;
  Map<String, bool> get guardianPermissions => _guardianPermissions;
  List<Map<String, dynamic>> get linkedGuardians => _linkedGuardians;
  bool get canViewDocuments =>
      !isGuardian || (_guardianPermissions['viewDocuments'] == true);
  bool get canViewMedicines =>
      !isGuardian || (_guardianPermissions['viewMedicines'] == true);
  bool get canManageMedicines =>
      !isGuardian || (_guardianPermissions['manageMedicines'] == true);
  bool get isLiveLocationSharing => _isLiveLocationSharing;
  DateTime? get liveLocationExpiresAt => _liveLocationExpiresAt;
  Map<String, dynamic>? get liveLocationSnapshot => _liveLocationSnapshot;
  String? get liveLocationStatusNote => _liveLocationStatusNote;
  bool get crisisModeEnabled => _crisisModeEnabled;
  List<Map<String, dynamic>> get guardianEmergencyResponses =>
      _guardianEmergencyResponses;
  Map<String, String> get reliabilityStatus => _reliabilityStatus;

  Duration? get liveLocationRemaining {
    final expiresAt = _liveLocationExpiresAt;
    if (!_isLiveLocationSharing || expiresAt == null) return null;
    final d = expiresAt.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _error = null;

    if (!FirebaseService.isReady) {
      _error = 'Backend is not configured. Please complete Firebase setup.';
      _setLoading(false);
      return false;
    }

    final firebaseUser = await FirebaseService.signIn(
      email: email.trim(),
      password: password,
    );
    if (firebaseUser != null) {
      _currentUser = firebaseUser;
      _selectedLanguage = _currentUser?.language ?? 'English';
      await _saveCurrentUser();
      await _saveSessionUid();
      await _postAuthWarmup();
      _setLoading(false);
      return true;
    }

    _error = FirebaseService.lastAuthError ??
        'Sign in failed. Check your email/password and try again.';
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
    _error = null;

    if (!FirebaseService.isReady) {
      _error = 'Backend is not configured. Please complete Firebase setup.';
      _setLoading(false);
      return false;
    }

    final firebaseUser = await FirebaseService.signUp(
      name: name,
      email: email.trim(),
      password: password,
      phone: phone,
      accountType: accountType,
      age: age,
      bloodGroup: bloodGroup,
      conditions: conditions,
    );
    if (firebaseUser != null) {
      _currentUser = firebaseUser;
      _selectedLanguage = _currentUser?.language ?? 'English';
      await _saveCurrentUser();
      await _saveSessionUid();
      await _postAuthWarmup();
      _setLoading(false);
      return true;
    }

    _error = FirebaseService.lastAuthError ??
        'Sign up failed. Please try again with a valid email/password.';
    _setLoading(false);
    return false;
  }

  Future<void> signOut() async {
    final userBeforeSignOut = _currentUser;
    final medsBeforeSignOut = List<MedicineReminder>.from(_medicines);
    final shouldStopLiveLocation = _isLiveLocationSharing &&
        userBeforeSignOut != null &&
        userBeforeSignOut.isPatient;

    _shouldStopWarmup = true; // Signal warmup to stop if running
    _cancelAllBackgroundTimers();

    _currentUser = null;
    _documents = [];
    _medicines = [];
    _appointments = [];
    _activePairingCode = null;
    _pendingPairingRequests = [];
    _linkedPatientId = null;
    _linkedPatientProfile = null;
    _linkedGuardians = [];
    _liveLocationSnapshot = null;
    _liveLocationExpiresAt = null;
    _isLiveLocationSharing = false;
    _isPushingLiveLocation = false;
    _isRefreshingLiveLocationSnapshot = false;
    _isGuardianLinkSyncRunning = false;
    _isSyncingRoleContext = false;
    _lastGuardianNotifiedLiveExpiry = null;
    _liveLocationStatusNote = null;
    _guardianEmergencyResponses = [];
    _reliabilityStatus = const {};
    _guardianPermissions = {
      'viewDocuments': true,
      'viewMedicines': true,
      'receiveEmergencyAlerts': true,
      'manageMedicines': false,
    };
    notifyListeners();

    if (shouldStopLiveLocation) {
      try {
        await FirebaseService.stopLiveLocation(
            patientId: userBeforeSignOut.uid);
      } catch (e) {
        print('Error stopping live location during sign-out: $e');
      }
    }
    for (final med in medsBeforeSignOut) {
      await _cancelMedicineReminders(med);
    }

    await FirebaseService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUidKey);
  }

  Future<void> _postAuthWarmup() async {
    _shouldStopWarmup = false; // Reset cancellation flag
    try {
      if (_shouldStopWarmup) return;
      await _syncRoleContext();

      if (_shouldStopWarmup) return;
      await _loadDocuments();

      if (_shouldStopWarmup) return;
      await _loadMedicines();

      if (_shouldStopWarmup) return;
      await _loadAppointments();

      if (_shouldStopWarmup) return;
      await refreshReliabilityStatus();
    } catch (e) {
      if (!_shouldStopWarmup) {
        // Only set error if not cancelled
        _error =
            'We signed you in, but some data failed to load. Pull to refresh.';
        print('Post-auth warmup failed: $e');
        notifyListeners();
      }
    }
  }

  void _cancelAllBackgroundTimers() {
    _liveLocationUpdateTimer?.cancel();
    _liveLocationUpdateTimer = null;
    _liveLocationExpiryTimer?.cancel();
    _liveLocationExpiryTimer = null;
    _guardianLiveLocationPollTimer?.cancel();
    _guardianLiveLocationPollTimer = null;
    _guardianLinkSyncTimer?.cancel();
    _guardianLinkSyncTimer = null;
  }

  String _effectiveDataOwnerUid() {
    if (isGuardian &&
        _linkedPatientId != null &&
        _linkedPatientId!.isNotEmpty) {
      return _linkedPatientId!;
    }
    return _currentUser?.uid ?? 'demo_001';
  }

  // ─── Documents ──────────────────────────────────────────────────

  Future<void> _loadDocuments() async {
    try {
      final uid = _effectiveDataOwnerUid();
      final cloudDocs = await FirebaseService.loadDocuments(uid);
      if (cloudDocs != null) {
        _documents = cloudDocs;
        await _saveDocumentsLocalOnly();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString('documents_$uid');
        if (jsonStr != null) {
          final List<dynamic> jsonList = jsonDecode(jsonStr);
          _documents = jsonList.map((e) => HealthDocument.fromMap(e)).toList();
          _documents.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
        } else {
          _documents = [];
        }
      }
    } catch (e) {
      print('Error loading documents: $e');
      _documents = [];
      _error = FirebaseService.lastServiceError ??
          'Unable to load documents right now.';
    }
    notifyListeners();
  }

  Future<void> _saveDocumentsLocalOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _effectiveDataOwnerUid();
      final jsonStr = jsonEncode(_documents.map((d) => d.toMap()).toList());
      await prefs.setString('documents_$uid', jsonStr);
    } catch (e) {
      print('Error saving documents: $e');
    }
  }

  Future<void> _saveDocuments() async {
    if (isGuardian) return;
    await _saveDocumentsLocalOnly();
    final uid = _currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseService.saveDocuments(uid, _documents);
    } catch (e) {
      print('Error syncing documents to cloud: $e');
      _error = FirebaseService.lastServiceError ??
          'Saved locally, but could not sync documents to cloud.';
      notifyListeners();
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
    if (isGuardian) return;
    _documents.insert(0, doc);
    await _saveDocuments();
    await AuditService.logEvent(
      ownerUserId: _effectiveDataOwnerUid(),
      event: 'document_uploaded',
      metadata: {
        'documentId': doc.id,
        'documentType': doc.documentType,
      },
    );
    notifyListeners();
  }

  Future<void> updateDocumentSummary(
      String docId, String summary, String language) async {
    if (isGuardian) return;
    final idx = _documents.indexWhere((d) => d.id == docId);
    if (idx == -1) return;
    final doc = _documents[idx];
    final updated = HealthDocument(
        id: doc.id,
        patientId: doc.patientId,
        name: doc.name,
        hospitalName: doc.hospitalName,
        documentType: doc.documentType,
        fileUrl: doc.fileUrl,
        fileType: doc.fileType,
        notes: doc.notes,
        aiSummary: language == 'English' ? summary : doc.aiSummary,
        aiSummaryHindi: language == 'Hindi' ? summary : doc.aiSummaryHindi,
        aiSummaryTelugu: language == 'Telugu' ? summary : doc.aiSummaryTelugu,
        aiSummaryKannada:
            language == 'Kannada' ? summary : doc.aiSummaryKannada,
        aiSummaryTamil: language == 'Tamil' ? summary : doc.aiSummaryTamil,
        uploadedAt: doc.uploadedAt,
        fileSize: doc.fileSize);
    _documents[idx] = updated;
    await _saveDocuments();
    notifyListeners();
  }

  Future<void> deleteDocument(String docId) async {
    if (isGuardian) return;
    _documents.removeWhere((d) => d.id == docId);
    await _saveDocuments();
    await AuditService.logEvent(
      ownerUserId: _effectiveDataOwnerUid(),
      event: 'document_deleted',
      metadata: {'documentId': docId},
    );
    notifyListeners();
  }

  // ─── Medicines ───────────────────────────────────────────────────

  Future<void> _loadMedicines() async {
    try {
      final uid = _effectiveDataOwnerUid();
      final cloudMeds = await FirebaseService.loadMedicines(uid);
      if (cloudMeds != null) {
        _medicines = cloudMeds;
        await _saveMedicinesLocalOnly();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString('medicines_$uid');
        if (jsonStr != null) {
          final List<dynamic> jsonList = jsonDecode(jsonStr);
          _medicines =
              jsonList.map((e) => MedicineReminder.fromMap(e)).toList();
        } else {
          _medicines = [];
        }
      }
      if (!isGuardian) {
        for (final med in _medicines.where((m) => m.isActive)) {
          await _scheduleMedicineReminders(med);
        }
        await _maybeNotifyMissedDoseAlert();
      }
    } catch (e) {
      print('Error loading medicines: $e');
      _medicines = [];
      _error = FirebaseService.lastServiceError ??
          'Unable to load medicines right now.';
    }
    notifyListeners();
  }

  Future<void> _loadAppointments() async {
    try {
      final uid = _effectiveDataOwnerUid();
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('appointments_$uid');
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _appointments = jsonList.map((e) => Appointment.fromMap(e)).toList();
        _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      } else {
        _appointments = [];
      }
    } catch (e) {
      print('Error loading appointments: $e');
      _appointments = [];
    }
    notifyListeners();
  }

  Future<void> _saveAppointments() async {
    if (isGuardian) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _effectiveDataOwnerUid();
      final jsonStr = jsonEncode(_appointments.map((a) => a.toMap()).toList());
      await prefs.setString('appointments_$uid', jsonStr);
    } catch (e) {
      print('Error saving appointments: $e');
    }
  }

  Future<void> _saveMedicinesLocalOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _effectiveDataOwnerUid();
      final jsonStr = jsonEncode(_medicines.map((m) => m.toMap()).toList());
      await prefs.setString('medicines_$uid', jsonStr);
    } catch (e) {
      print('Error saving medicines: $e');
    }
  }

  Future<void> _saveMedicines() async {
    if (isGuardian && !canManageMedicines) return;
    await _saveMedicinesLocalOnly();
    final uid = _effectiveDataOwnerUid();
    if (uid.isEmpty) return;
    try {
      await FirebaseService.saveMedicines(uid, _medicines);
    } catch (e) {
      print('Error syncing medicines to cloud: $e');
      _error = FirebaseService.lastServiceError ??
          'Saved locally, but could not sync medicines to cloud.';
      notifyListeners();
    }
  }

  Future<void> addMedicine(MedicineReminder med) async {
    if (isGuardian && !canManageMedicines) return;
    _medicines.add(med);
    notifyListeners();

    await _saveMedicines();
    if (!isGuardian) {
      await _scheduleMedicineReminders(med);
    }
    await AuditService.logEvent(
      ownerUserId: _effectiveDataOwnerUid(),
      event: 'medicine_added',
      metadata: {'medicineId': med.id, 'name': med.medicineName},
    );
  }

  Future<void> deleteMedicine(String medId) async {
    if (isGuardian && !canManageMedicines) return;
    final med = _medicines
        .cast<MedicineReminder?>()
        .firstWhere((m) => m?.id == medId, orElse: () => null);
    if (med != null && !isGuardian) {
      await _cancelMedicineReminders(med);
    }
    _medicines.removeWhere((m) => m.id == medId);
    notifyListeners();

    await _saveMedicines();
    await AuditService.logEvent(
      ownerUserId: _effectiveDataOwnerUid(),
      event: 'medicine_deleted',
      metadata: {'medicineId': medId},
    );
  }

  Future<void> setMedicineTakenToday(String medId, bool taken) async {
    if (isGuardian && !canManageMedicines) return;
    final idx = _medicines.indexWhere((m) => m.id == medId);
    if (idx == -1) return;
    final med = _medicines[idx];
    _medicines[idx] = MedicineReminder(
      id: med.id,
      patientId: med.patientId,
      medicineName: med.medicineName,
      dosage: med.dosage,
      frequency: med.frequency,
      times: med.times,
      duration: med.duration,
      startDate: med.startDate,
      endDate: med.endDate,
      isActive: med.isActive,
      lastTakenAt: taken ? DateTime.now() : null,
      notes: med.notes,
      color: med.color,
    );
    notifyListeners();

    await _saveMedicines();
    await AuditService.logEvent(
      ownerUserId: _effectiveDataOwnerUid(),
      event: 'medicine_taken_status_changed',
      metadata: {'medicineId': medId, 'taken': taken},
    );
  }

  Future<void> addAppointment(Appointment appt) async {
    if (isGuardian) return;
    _appointments.add(appt);
    _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _saveAppointments();
    await AuditService.logEvent(
      ownerUserId: _effectiveDataOwnerUid(),
      event: 'appointment_added',
      metadata: {'appointmentId': appt.id, 'title': appt.title},
    );
    notifyListeners();
  }

  Future<void> deleteAppointment(String apptId) async {
    if (isGuardian) return;
    _appointments.removeWhere((a) => a.id == apptId);
    await _saveAppointments();
    await AuditService.logEvent(
      ownerUserId: _effectiveDataOwnerUid(),
      event: 'appointment_deleted',
      metadata: {'appointmentId': apptId},
    );
    notifyListeners();
  }

  Future<void> toggleAppointmentCompleted(String apptId) async {
    if (isGuardian) return;
    final idx = _appointments.indexWhere((a) => a.id == apptId);
    if (idx == -1) return;
    final item = _appointments[idx];
    _appointments[idx] = Appointment(
      id: item.id,
      patientId: item.patientId,
      title: item.title,
      hospital: item.hospital,
      dateTime: item.dateTime,
      notes: item.notes,
      completed: !item.completed,
    );
    await _saveAppointments();
    await AuditService.logEvent(
      ownerUserId: _effectiveDataOwnerUid(),
      event: 'appointment_completion_toggled',
      metadata: {
        'appointmentId': apptId,
        'completed': _appointments[idx].completed
      },
    );
    notifyListeners();
  }

  // ─── Utils ───────────────────────────────────────────────────────

  Future<void> setCrisisModeEnabled(bool enabled) async {
    _crisisModeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crisisModeKey, enabled);
    notifyListeners();
  }

  Future<void> submitGuardianEmergencyResponse(
    String response, {
    int? etaMinutes,
  }) async {
    if (!isGuardian) return;
    final patientId = _linkedPatientId;
    if (patientId == null || patientId.isEmpty) return;

    final ok = await FirebaseService.upsertGuardianEmergencyResponse(
      patientId: patientId,
      response: response,
      etaMinutes: etaMinutes,
    );
    if (!ok) return;

    await refreshGuardianEmergencyResponses();
    await AuditService.logEvent(
      ownerUserId: patientId,
      event: 'guardian_emergency_response',
      metadata: {
        'response': response,
        if (etaMinutes != null) 'etaMinutes': etaMinutes,
      },
    );
  }

  Future<void> refreshGuardianEmergencyResponses() async {
    final patientId = isGuardian ? _linkedPatientId : _currentUser?.uid;
    if (patientId == null || patientId.isEmpty) {
      _guardianEmergencyResponses = [];
      notifyListeners();
      return;
    }

    _guardianEmergencyResponses =
        await FirebaseService.loadGuardianEmergencyResponses(patientId);
    notifyListeners();
  }

  Future<void> refreshReliabilityStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final role = isGuardian ? 'Guardian' : 'Patient';
    final linked = isGuardian
        ? ((_linkedPatientId != null && _linkedPatientId!.isNotEmpty)
            ? 'Linked'
            : 'Not linked')
        : 'Self';
    final liveStatus = _liveLocationSnapshot == null
        ? 'No data'
        : (_liveLocationSnapshot?['isSharing'] == true
            ? 'Live sharing active'
            : 'Idle');

    _reliabilityStatus = {
      'Backend': FirebaseService.isReady ? 'Connected' : 'Not configured',
      'Role': role,
      'Link': linked,
      'Location Service': serviceEnabled ? 'Enabled' : 'Disabled',
      'Live Snapshot': liveStatus,
      'Last Sync': DateTime.now().toIso8601String(),
    };
    notifyListeners();
  }

  void setLanguage(String language) {
    _selectedLanguage = language;
    if (_currentUser != null) {
      final user = _currentUser!;
      _currentUser = AppUser(
        uid: user.uid,
        name: user.name,
        email: user.email,
        phone: user.phone,
        accountType: user.accountType,
        language: language,
        linkedPatientId: user.linkedPatientId,
        guardianIds: user.guardianIds,
        emergencyContacts: user.emergencyContacts,
        createdAt: user.createdAt,
        age: user.age,
        bloodGroup: user.bloodGroup,
        conditions: user.conditions,
      );
      _saveCurrentUser();
    }
    notifyListeners();
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    if (isGuardian) return;
    final user = _currentUser;
    if (user == null) return;

    final exists = user.emergencyContacts.any(
      (c) => c.phone.trim() == contact.phone.trim(),
    );
    if (exists) return;

    final updatedContacts = [...user.emergencyContacts, contact];
    _currentUser = AppUser(
      uid: user.uid,
      name: user.name,
      email: user.email,
      phone: user.phone,
      accountType: user.accountType,
      language: user.language,
      linkedPatientId: user.linkedPatientId,
      guardianIds: user.guardianIds,
      emergencyContacts: updatedContacts,
      createdAt: user.createdAt,
      age: user.age,
      bloodGroup: user.bloodGroup,
      conditions: user.conditions,
    );
    await _saveCurrentUser();
    await AuditService.logEvent(
      ownerUserId: _effectiveDataOwnerUid(),
      event: 'emergency_contact_added',
      metadata: {'name': contact.name, 'phone': contact.phone},
    );
    notifyListeners();
  }

  Future<void> removeEmergencyContact(String phone) async {
    if (isGuardian) return;
    final user = _currentUser;
    if (user == null) return;

    final updatedContacts = user.emergencyContacts
        .where((c) => c.phone.trim() != phone.trim())
        .toList();

    _currentUser = AppUser(
      uid: user.uid,
      name: user.name,
      email: user.email,
      phone: user.phone,
      accountType: user.accountType,
      language: user.language,
      linkedPatientId: user.linkedPatientId,
      guardianIds: user.guardianIds,
      emergencyContacts: updatedContacts,
      createdAt: user.createdAt,
      age: user.age,
      bloodGroup: user.bloodGroup,
      conditions: user.conditions,
    );
    await _saveCurrentUser();
    await AuditService.logEvent(
      ownerUserId: _effectiveDataOwnerUid(),
      event: 'emergency_contact_removed',
      metadata: {'phone': phone},
    );
    notifyListeners();
  }

  DateTime? _dateTimeForTimeToday(String timeRaw) {
    final text = timeRaw.trim();
    if (text.isEmpty) return null;

    try {
      final upper = text.toUpperCase();
      final parts = text.split(':');
      if (parts.length < 2) return null;

      var hour = int.parse(parts[0].trim());
      final minuteToken = parts[1].trim().split(' ').first;
      final minute = int.parse(minuteToken);

      final isPm = upper.contains('PM');
      final isAm = upper.contains('AM');
      if (isPm && hour < 12) {
        hour += 12;
      } else if (isAm && hour == 12) {
        hour = 0;
      }

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  bool _isTakenToday(MedicineReminder med) {
    final takenAt = med.lastTakenAt;
    if (takenAt == null) return false;
    final now = DateTime.now();
    return takenAt.year == now.year &&
        takenAt.month == now.month &&
        takenAt.day == now.day;
  }

  List<MedicineReminder> overdueMedicinesNow({
    Duration grace = const Duration(minutes: 45),
  }) {
    final now = DateTime.now();
    return _medicines.where((med) {
      if (!med.isActive) return false;
      if (_isTakenToday(med)) return false;

      for (final slot in med.times) {
        final due = _dateTimeForTimeToday(slot);
        if (due == null) continue;
        if (now.isAfter(due.add(grace))) return true;
      }
      return false;
    }).toList();
  }

  int missedDoseCountNow() => overdueMedicinesNow().length;

  Future<void> _maybeNotifyMissedDoseAlert() async {
    final uid = _currentUser?.uid;
    if (uid == null) return;

    final overdue = overdueMedicinesNow();
    if (overdue.isEmpty) return;

    final now = DateTime.now();
    final todayToken =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final key = 'missed_alert_sent_${uid}_$todayToken';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) == true) return;

    await NotificationService.showMissedDoseAlert(
      patientName: _currentUser?.name ?? 'Patient',
      count: overdue.length,
    );
    await prefs.setBool(key, true);
  }

  Future<String?> exportDataToJsonFile() async {
    final user = _currentUser;
    if (user == null) return null;

    final payload = {
      'generatedAt': DateTime.now().toIso8601String(),
      'user': user.toMap(),
      'documents': _documents.map((d) => d.toMap()).toList(),
      'medicines': _medicines.map((m) => m.toMap()).toList(),
      'linkedGuardians': _linkedGuardians,
      'guardianPermissions': _guardianPermissions,
    };

    final encoder = const JsonEncoder.withIndent('  ');
    final jsonText = encoder.convert(payload);
    final exportDir = await _resolveExportDirectory();
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final filePath =
        '${exportDir.path}/healthvault_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(filePath);
    await file.writeAsString(jsonText, flush: true);

    await AuditService.logEvent(
      ownerUserId: user.uid,
      event: 'data_exported',
      metadata: {'filePath': filePath},
    );
    return filePath;
  }

  Future<Directory> _resolveExportDirectory() async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        return Directory('${downloadsDir.path}/HealthVault Exports');
      }
    } catch (_) {
      // Ignore and fallback.
    }

    try {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        return Directory('${external.path}/exports');
      }
    } catch (_) {
      // Ignore and fallback.
    }

    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/exports');
  }

  Future<bool> deleteMyHealthData() async {
    final user = _currentUser;
    if (user == null || !user.isPatient) return false;

    try {
      await FirebaseService.clearDocuments(user.uid);
      await FirebaseService.clearMedicines(user.uid);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('documents_${user.uid}');
      await prefs.remove('medicines_${user.uid}');

      _documents = [];
      _medicines = [];

      _currentUser = AppUser(
        uid: user.uid,
        name: user.name,
        email: user.email,
        phone: user.phone,
        accountType: user.accountType,
        language: user.language,
        linkedPatientId: user.linkedPatientId,
        guardianIds: user.guardianIds,
        emergencyContacts: const [],
        createdAt: user.createdAt,
        age: user.age,
        bloodGroup: user.bloodGroup,
        conditions: user.conditions,
      );
      await _saveCurrentUser();
      await AuditService.logEvent(
        ownerUserId: user.uid,
        event: 'patient_health_data_deleted',
      );
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting health data: $e');
      return false;
    }
  }

  Future<String?> startEmergencyLiveLocationSharing({
    Duration duration = const Duration(minutes: 30),
  }) async {
    final user = _currentUser;
    if (user == null || !user.isPatient) {
      return 'Only patient accounts can start live location sharing.';
    }

    if (_isLiveLocationSharing) {
      return null;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _liveLocationStatusNote =
          'Location service is disabled. Please turn on GPS.';
      notifyListeners();
      return 'Location service is disabled. Please turn on GPS.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _liveLocationStatusNote = 'Location permission denied.';
      notifyListeners();
      return 'Location permission denied.';
    }
    if (permission == LocationPermission.deniedForever) {
      _liveLocationStatusNote =
          'Location permission permanently denied. Enable it from app settings.';
      notifyListeners();
      return 'Location permission permanently denied. Enable it from app settings.';
    }

    await stopEmergencyLiveLocationSharing();

    _isLiveLocationSharing = true;
    _liveLocationExpiresAt = DateTime.now().add(duration);
    notifyListeners();

    final firstError = await _captureAndPushLiveLocation();
    if (firstError != null) {
      _liveLocationStatusNote = firstError;
      await stopEmergencyLiveLocationSharing();
      return firstError;
    }

    _liveLocationUpdateTimer =
        Timer.periodic(const Duration(seconds: 25), (timer) async {
      if (!_isLiveLocationSharing) {
        timer.cancel();
        return;
      }
      final expiresAt = _liveLocationExpiresAt;
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        await stopEmergencyLiveLocationSharing(expired: true);
        return;
      }
      await _captureAndPushLiveLocation();
    });

    _liveLocationExpiryTimer = Timer(duration, () async {
      await stopEmergencyLiveLocationSharing(expired: true);
    });

    await AuditService.logEvent(
      ownerUserId: user.uid,
      event: 'live_location_started',
      metadata: {'durationMinutes': duration.inMinutes},
    );
    _liveLocationStatusNote = 'Live location sharing is active.';
    notifyListeners();

    return null;
  }

  Future<void> stopEmergencyLiveLocationSharing({bool expired = false}) async {
    _liveLocationUpdateTimer?.cancel();
    _liveLocationUpdateTimer = null;
    _liveLocationExpiryTimer?.cancel();
    _liveLocationExpiryTimer = null;

    final user = _currentUser;
    final wasSharing = _isLiveLocationSharing;
    _isLiveLocationSharing = false;
    _liveLocationExpiresAt = null;
    _liveLocationStatusNote = expired
        ? 'Live location auto-stopped after timeout.'
        : 'Live location sharing stopped.';
    notifyListeners();

    if (user != null && user.isPatient) {
      await FirebaseService.stopLiveLocation(patientId: user.uid);
      if (wasSharing) {
        await AuditService.logEvent(
          ownerUserId: user.uid,
          event:
              expired ? 'live_location_auto_stopped' : 'live_location_stopped',
        );
      }
    }
  }

  Future<void> refreshLiveLocationSnapshot() async {
    if (_isRefreshingLiveLocationSnapshot) return;

    final targetPatientId =
        isGuardian ? (_linkedPatientId ?? '') : (_currentUser?.uid ?? '');
    if (targetPatientId.isEmpty) {
      _liveLocationSnapshot = null;
      notifyListeners();
      return;
    }

    _isRefreshingLiveLocationSnapshot = true;
    try {
      final data =
          await FirebaseService.loadLiveLocation(patientId: targetPatientId);
      _liveLocationSnapshot = data;
      _guardianEmergencyResponses =
          await FirebaseService.loadGuardianEmergencyResponses(targetPatientId);

      final readError = (data?['readError'] ?? '').toString();
      if (readError.isNotEmpty) {
        _liveLocationStatusNote = 'Live location read failed: $readError';
      } else if ((data?['isSharing'] == true) &&
          data?['latitude'] != null &&
          data?['longitude'] != null) {
        _liveLocationStatusNote = 'Live location updated.';
      }

      if (!isGuardian) {
        _isLiveLocationSharing = data?['isSharing'] == true;
        _liveLocationExpiresAt = data?['expiresAt'] is DateTime
            ? data!['expiresAt'] as DateTime
            : null;
      } else {
        final isSharing = data?['isSharing'] == true;
        final expiresAt = data?['expiresAt'] is DateTime
            ? data!['expiresAt'] as DateTime
            : null;
        final shouldNotify = isSharing &&
            expiresAt != null &&
            (_lastGuardianNotifiedLiveExpiry == null ||
                !_lastGuardianNotifiedLiveExpiry!.isAtSameMomentAs(expiresAt));
        if (shouldNotify) {
          _lastGuardianNotifiedLiveExpiry = expiresAt;
          unawaited(NotificationService.showGuardianUpdate(
            patientName: _linkedPatientProfile?.name ?? 'Patient',
            update: 'Emergency live location sharing has started.',
          ));
        }
      }

      notifyListeners();
    } finally {
      _isRefreshingLiveLocationSnapshot = false;
    }
  }

  Future<String?> _captureAndPushLiveLocation() async {
    if (_isPushingLiveLocation) return null;

    final user = _currentUser;
    final expiresAt = _liveLocationExpiresAt;
    if (user == null || !user.isPatient || expiresAt == null) {
      return 'Live location is not active.';
    }

    _isPushingLiveLocation = true;
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).timeout(const Duration(seconds: 12));
      } on TimeoutException {
        pos = await Geolocator.getLastKnownPosition();
      }

      pos ??= await Geolocator.getLastKnownPosition();
      if (pos == null) {
        return 'Could not get GPS fix yet. Try again near a window or outdoors.';
      }

      await FirebaseService.upsertLiveLocation(
        patientId: user.uid,
        latitude: pos.latitude,
        longitude: pos.longitude,
        expiresAt: expiresAt,
        isSharing: true,
      );

      _liveLocationSnapshot = {
        'patientId': user.uid,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'isSharing': true,
        'expiresAt': expiresAt,
        'updatedAt': DateTime.now(),
      };
      _liveLocationStatusNote = 'Live location pushed successfully.';
      notifyListeners();
      return null;
    } catch (e) {
      print('Error capturing live location: $e');
      final errorText = e.toString();
      if (errorText.contains('permission')) {
        return 'Location permission missing. Please allow location for this app.';
      }
      if (errorText.contains('location services are disabled')) {
        return 'Location services are disabled. Turn on device location.';
      }
      return 'Unable to capture current location.';
    } finally {
      _isPushingLiveLocation = false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _scheduleMedicineReminders(MedicineReminder med) async {
    try {
      for (int i = 0; i < med.times.length; i++) {
        await NotificationService.scheduleMedicineReminder(
          id: _reminderId(med.id, i),
          medicineName: med.medicineName,
          dosage: med.dosage,
          time: med.times[i],
        );
      }
    } catch (e) {
      print('Error scheduling reminders for ${med.medicineName}: $e');
    }
  }

  Future<void> _cancelMedicineReminders(MedicineReminder med) async {
    try {
      final ids =
          List.generate(med.times.length, (i) => _reminderId(med.id, i));
      await NotificationService.cancelMedicineReminders(ids);
    } catch (e) {
      print('Error canceling reminders for ${med.medicineName}: $e');
    }
  }

  int _reminderId(String medId, int index) {
    int hash = 17;
    final seed = '$medId#$index';
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }

  String _profileKey(String uid) => 'user_profile_$uid';

  Future<void> _saveSessionUid() async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUidKey, uid);
  }

  Future<void> _saveCurrentUser() async {
    final user = _currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey(user.uid), jsonEncode(user.toMap()));
    await FirebaseService.saveUserProfile(user);
  }

  Future<AppUser?> _loadUserProfile(String uid) async {
    final cloud = await FirebaseService.loadUserProfile(uid);
    if (cloud != null) return cloud;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(uid));
    if (raw == null) return null;
    try {
      return AppUser.fromMap(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> _restoreSession() async {
    try {
      // First, check if Firebase Auth has an active session
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
        final profile = await _loadUserProfile(firebaseUser.uid);
        if (profile != null) {
          _currentUser = profile;
          _selectedLanguage = profile.language;
          await _saveSessionUid();
          await _saveCurrentUser();
          await _syncRoleContext();
          await _loadDocuments();
          await _loadMedicines();
          await _loadAppointments();
          notifyListeners();
          return;
        }
      }

      // Fallback: check local storage for last logged-in user
      final prefs = await SharedPreferences.getInstance();
      _crisisModeEnabled = prefs.getBool(_crisisModeKey) ?? false;
      final uid = prefs.getString(_currentUidKey);
      if (uid == null) return;

      final user = await _loadUserProfile(uid);
      if (user == null) return;

      _currentUser = user;
      _selectedLanguage = user.language;
      await _syncRoleContext();
      await _loadDocuments();
      await _loadMedicines();
      await _loadAppointments();
      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
  }

  Future<void> _syncRoleContext() async {
    if (_isSyncingRoleContext) return;

    _isSyncingRoleContext = true;
    try {
      final user = _currentUser;
      if (user == null) return;

      if (user.isPatient) {
        _guardianLinkSyncTimer?.cancel();
        _guardianLinkSyncTimer = null;
        _linkedPatientId = null;
        _linkedPatientProfile = null;
        _guardianPermissions = {
          'viewDocuments': true,
          'viewMedicines': true,
          'receiveEmergencyAlerts': true,
          'manageMedicines': false,
        };
        await refreshPendingPairingRequests();
        await refreshLinkedGuardians();
        await refreshLiveLocationSnapshot();
        await refreshGuardianEmergencyResponses();
        _configureGuardianLiveLocationPolling();
        return;
      }

      _activePairingCode = null;
      _pendingPairingRequests = [];
      _linkedPatientId =
          await FirebaseService.loadLinkedPatientIdForGuardian(user.uid);
      if (_linkedPatientId != null && _linkedPatientId!.isNotEmpty) {
        _linkedPatientProfile =
            await FirebaseService.loadUserProfile(_linkedPatientId!);
        final link =
            await FirebaseService.loadActiveCareLinkForGuardian(user.uid);
        final rawPermissions = link?['permissions'];
        if (rawPermissions is Map<String, dynamic>) {
          _guardianPermissions = {
            'viewDocuments': rawPermissions['viewDocuments'] == true,
            'viewMedicines': rawPermissions['viewMedicines'] == true,
            'receiveEmergencyAlerts':
                rawPermissions['receiveEmergencyAlerts'] == true,
            'manageMedicines': rawPermissions['manageMedicines'] == true,
          };
        }
      } else {
        _linkedPatientProfile = null;
        _documents = [];
        _medicines = [];
        _liveLocationSnapshot = null;
        _guardianPermissions = {
          'viewDocuments': false,
          'viewMedicines': false,
          'receiveEmergencyAlerts': false,
          'manageMedicines': false,
        };
      }

      await refreshLiveLocationSnapshot();
      await refreshGuardianEmergencyResponses();
      _configureGuardianLiveLocationPolling();
      _configureGuardianLinkSync();
    } finally {
      _isSyncingRoleContext = false;
    }
  }

  void _configureGuardianLiveLocationPolling() {
    _guardianLiveLocationPollTimer?.cancel();
    _guardianLiveLocationPollTimer = null;

    if (!isGuardian || _linkedPatientId == null || _linkedPatientId!.isEmpty) {
      return;
    }

    _guardianLiveLocationPollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        unawaited(refreshLiveLocationSnapshot());
      },
    );
  }

  void _configureGuardianLinkSync() {
    _guardianLinkSyncTimer?.cancel();
    _guardianLinkSyncTimer = null;

    if (!isGuardian) return;

    _guardianLinkSyncTimer =
        Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_isGuardianLinkSyncRunning) return;
      _isGuardianLinkSyncRunning = true;
      try {
        if (!isGuardian) {
          _guardianLinkSyncTimer?.cancel();
          _guardianLinkSyncTimer = null;
          _isGuardianLinkSyncRunning = false;
          return;
        }

        final user = _currentUser;
        if (user == null) return;

        final linked =
            await FirebaseService.loadLinkedPatientIdForGuardian(user.uid);
        if (linked != null && linked.isNotEmpty && linked != _linkedPatientId) {
          await _syncRoleContext();
          await _loadDocuments();
          await _loadMedicines();
          notifyListeners();
        }

        if (_linkedPatientId != null && _linkedPatientId!.isNotEmpty) {
          _guardianLinkSyncTimer?.cancel();
          _guardianLinkSyncTimer = null;
        }
      } finally {
        _isGuardianLinkSyncRunning = false;
      }
    });
  }

  Future<String?> generatePairingCode() async {
    final user = _currentUser;
    if (user == null || !user.isPatient) return null;
    final code = await FirebaseService.generatePairingCode(user.uid);
    _activePairingCode = code;
    notifyListeners();
    return code;
  }

  Future<String?> requestPatientLink(String code) async {
    final user = _currentUser;
    if (user == null || !user.isGuardian)
      return 'Only guardian accounts can request pairing.';
    _error = null;
    final error = await FirebaseService.submitPairingRequest(code);
    if (error == null) {
      await _syncRoleContext();
      await _loadDocuments();
      await _loadMedicines();
      notifyListeners();
    } else {
      _error = error;
      notifyListeners();
    }
    return error;
  }

  Future<void> refreshPendingPairingRequests() async {
    final user = _currentUser;
    if (user == null || !user.isPatient) {
      _pendingPairingRequests = [];
      notifyListeners();
      return;
    }
    _pendingPairingRequests =
        await FirebaseService.loadPendingPairingRequests(user.uid);
    notifyListeners();
  }

  Future<bool> approvePairingRequest(String requestId) async {
    final ok = await FirebaseService.approvePairingRequest(requestId);
    if (ok) {
      await refreshPendingPairingRequests();
      await refreshLinkedGuardians();
      final refreshed = await _loadUserProfile(_currentUser!.uid);
      if (refreshed != null) {
        _currentUser = refreshed;
        await _saveCurrentUser();
      }
      await AuditService.logEvent(
        ownerUserId: _effectiveDataOwnerUid(),
        event: 'pairing_request_approved',
        metadata: {'requestId': requestId},
      );
      notifyListeners();
    }
    return ok;
  }

  Future<bool> rejectPairingRequest(String requestId) async {
    final ok = await FirebaseService.rejectPairingRequest(requestId);
    if (ok) {
      await refreshPendingPairingRequests();
      await AuditService.logEvent(
        ownerUserId: _effectiveDataOwnerUid(),
        event: 'pairing_request_rejected',
        metadata: {'requestId': requestId},
      );
    }
    return ok;
  }

  Future<void> refreshLinkedGuardians() async {
    final user = _currentUser;
    if (user == null || !user.isPatient) {
      _linkedGuardians = [];
      notifyListeners();
      return;
    }

    final links = await FirebaseService.loadActiveCareLinksForPatient(user.uid);
    final resolved = <Map<String, dynamic>>[];
    for (final link in links) {
      final guardianId = (link['guardianId'] ?? '').toString();
      if (guardianId.isEmpty) continue;
      final guardian = await FirebaseService.loadUserProfile(guardianId);
      resolved.add({
        ...link,
        'guardianName': guardian?.name ?? 'Guardian',
        'guardianEmail': guardian?.email ?? '',
      });
    }
    _linkedGuardians = resolved;
    notifyListeners();
  }

  Future<bool> updateGuardianPermissions({
    required String guardianId,
    required Map<String, bool> permissions,
  }) async {
    final user = _currentUser;
    if (user == null || !user.isPatient) return false;

    final ok = await FirebaseService.updateGuardianPermissions(
      patientId: user.uid,
      guardianId: guardianId,
      permissions: permissions,
    );

    if (ok) {
      _error = null;
      await refreshLinkedGuardians();
      await AuditService.logEvent(
        ownerUserId: _effectiveDataOwnerUid(),
        event: 'guardian_permissions_updated',
        metadata: {
          'guardianId': guardianId,
          'permissions': permissions,
        },
      );
    } else {
      _error = FirebaseService.lastServiceError ??
          'Could not update guardian permissions right now.';
      notifyListeners();
    }
    return ok;
  }

  Future<bool> unlinkGuardian(String guardianId) async {
    final user = _currentUser;
    if (user == null || !user.isPatient) return false;

    final ok = await FirebaseService.unlinkGuardianForPatient(
      patientId: user.uid,
      guardianId: guardianId,
    );

    if (ok) {
      _error = null;
      final updatedGuardianIds = user.guardianIds
          .where((id) => id != guardianId)
          .toList(growable: false);
      _currentUser = AppUser(
        uid: user.uid,
        name: user.name,
        email: user.email,
        phone: user.phone,
        accountType: user.accountType,
        language: user.language,
        linkedPatientId: user.linkedPatientId,
        guardianIds: updatedGuardianIds,
        emergencyContacts: user.emergencyContacts,
        createdAt: user.createdAt,
        age: user.age,
        bloodGroup: user.bloodGroup,
        conditions: user.conditions,
      );
      await _saveCurrentUser();
      await refreshLinkedGuardians();
      await AuditService.logEvent(
        ownerUserId: _effectiveDataOwnerUid(),
        event: 'guardian_unlinked',
        metadata: {'guardianId': guardianId},
      );
      notifyListeners();
    } else {
      _error = FirebaseService.lastServiceError ??
          'Could not unlink guardian right now.';
      notifyListeners();
    }
    return ok;
  }

  Future<void> refreshRoleContext() async {
    await _syncRoleContext();
    await _loadDocuments();
    await _loadMedicines();
    await refreshLiveLocationSnapshot();
    await refreshGuardianEmergencyResponses();
    await refreshReliabilityStatus();
    notifyListeners();
  }
}
