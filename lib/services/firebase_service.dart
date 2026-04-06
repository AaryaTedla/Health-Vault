import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class FirebaseService {
  static bool _isReady = false;
  static bool get isReady => _isReady;
  static String? get currentUid =>
      _isReady ? FirebaseAuth.instance.currentUser?.uid : null;
  static String? _lastAuthError;
  static String? get lastAuthError => _lastAuthError;
  static String? _lastServiceError;
  static String? get lastServiceError => _lastServiceError;

  static void _clearServiceError() {
    _lastServiceError = null;
  }

  static void _setServiceError(String message, [Object? error]) {
    _lastServiceError = message;
    if (error != null) {
      debugPrint('FirebaseService error: $message | $error');
    } else {
      debugPrint('FirebaseService error: $message');
    }
  }

  static Future<void> init() async {
    _clearServiceError();
    try {
      await Firebase.initializeApp();
      _isReady = true;
    } catch (e) {
      _isReady = false;
      _setServiceError('Failed to initialize Firebase.', e);
    }
  }

  static Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    _lastAuthError = null;
    _clearServiceError();
    if (!_isReady) return null;
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final firebaseUser = credential.user;
      if (firebaseUser == null) return null;

      final existing = await loadUserProfile(firebaseUser.uid);
      if (existing != null) return existing;

      final fallback = AppUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? email.split('@').first,
        email: firebaseUser.email ?? email,
        phone: firebaseUser.phoneNumber ?? '',
        accountType: 'patient',
        language: 'English',
        createdAt: DateTime.now(),
        conditions: const [],
        emergencyContacts: const [],
      );
      try {
        await saveUserProfile(fallback);
      } catch (e) {
        // Keep sign-in successful even if profile sync fails temporarily.
        _setServiceError('Signed in, but could not sync your profile yet.', e);
      }
      return fallback;
    } on FirebaseAuthException catch (e) {
      if (_isConfigurationNotFound(e.code, e.message)) {
        final restUser = await _signInWithRest(
          email: email,
          password: password,
        );
        if (restUser != null) return restUser;
      }
      _lastAuthError = _mapAuthError(e.code, e.message);
      return null;
    } catch (e) {
      _lastAuthError = 'Unable to sign in right now. Please try again.';
      _setServiceError('Sign-in failed unexpectedly.', e);
      return null;
    }
  }

  static Future<AppUser?> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String accountType,
    int? age,
    String? bloodGroup,
    List<String> conditions = const [],
  }) async {
    _lastAuthError = null;
    _clearServiceError();
    if (!_isReady) return null;
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final firebaseUser = credential.user;
      if (firebaseUser == null) return null;

      await firebaseUser.updateDisplayName(name);

      final profile = AppUser(
        uid: firebaseUser.uid,
        name: name,
        email: email,
        phone: phone,
        accountType: accountType,
        language: 'English',
        createdAt: DateTime.now(),
        age: age,
        bloodGroup: bloodGroup,
        conditions: conditions,
        emergencyContacts: const [],
      );
      try {
        await saveUserProfile(profile);
      } catch (e) {
        // Account creation succeeded; do not fail signup if Firestore sync fails.
        _setServiceError('Account created, but profile sync is pending.', e);
      }
      return profile;
    } on FirebaseAuthException catch (e) {
      if (_isConfigurationNotFound(e.code, e.message)) {
        final restUser = await _signUpWithRest(
          name: name,
          email: email,
          password: password,
          phone: phone,
          accountType: accountType,
          age: age,
          bloodGroup: bloodGroup,
          conditions: conditions,
        );
        if (restUser != null) return restUser;
      }
      _lastAuthError = _mapAuthError(e.code, e.message);
      return null;
    } catch (e) {
      _lastAuthError = 'Unable to create account right now. Please try again.';
      _setServiceError('Sign-up failed unexpectedly.', e);
      return null;
    }
  }

  static Future<void> signOut() async {
    _clearServiceError();
    if (!_isReady) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Ignore sign-out failures for local fallback mode.
      _setServiceError('Failed to sign out from Firebase.', e);
    }
  }

  static Future<void> saveUserProfile(AppUser user) async {
    _clearServiceError();
    if (!_isReady) return;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != user.uid) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      // Keep app functional in fallback mode when SDK-auth is unavailable.
      _setServiceError('Could not save profile to cloud.', e);
    }
  }

  static Future<AppUser?> loadUserProfile(String uid) async {
    _clearServiceError();
    if (!_isReady) return null;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snap.exists || snap.data() == null) return null;
      return AppUser.fromMap(snap.data()!);
    } catch (e) {
      _setServiceError('Could not load user profile from cloud.', e);
      return null;
    }
  }

  static Future<List<HealthDocument>?> loadDocuments(String uid) async {
    _clearServiceError();
    if (!_isReady) return null;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return null;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('documents')
          .get();
      final docs = snap.docs
          .map((d) => HealthDocument.fromMap(d.data()))
          .toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return docs;
    } catch (e) {
      _setServiceError('Could not load documents from cloud.', e);
      return null;
    }
  }

  static Future<void> saveDocuments(
      String uid, List<HealthDocument> docs) async {
    _clearServiceError();
    if (!_isReady) return;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != uid) return;

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('documents');

    final batch = FirebaseFirestore.instance.batch();
    final keepIds = docs.map((d) => d.id).toSet();

    for (final doc in docs) {
      batch.set(collection.doc(doc.id), doc.toMap(), SetOptions(merge: true));
    }

    final existing = await collection.get();
    for (final item in existing.docs) {
      if (!keepIds.contains(item.id)) {
        batch.delete(item.reference);
      }
    }

    try {
      await batch.commit();
    } catch (e) {
      _setServiceError('Could not sync documents to cloud.', e);
      rethrow;
    }
  }

  static Future<List<MedicineReminder>?> loadMedicines(String uid) async {
    _clearServiceError();
    if (!_isReady) return null;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return null;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medicines')
          .get();
      return snap.docs.map((d) => MedicineReminder.fromMap(d.data())).toList();
    } catch (e) {
      _setServiceError('Could not load medicines from cloud.', e);
      return null;
    }
  }

  static Future<void> saveMedicines(
      String uid, List<MedicineReminder> medicines) async {
    _clearServiceError();
    if (!_isReady) return;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines');

    final batch = FirebaseFirestore.instance.batch();
    final keepIds = medicines.map((m) => m.id).toSet();

    for (final med in medicines) {
      batch.set(collection.doc(med.id), med.toMap(), SetOptions(merge: true));
    }

    final existing = await collection.get();
    for (final item in existing.docs) {
      if (!keepIds.contains(item.id)) {
        batch.delete(item.reference);
      }
    }

    try {
      await batch.commit();
    } catch (e) {
      _setServiceError('Could not sync medicines to cloud.', e);
      rethrow;
    }
  }

  static Future<void> clearDocuments(String uid) async {
    await saveDocuments(uid, const []);
  }

  static Future<void> clearMedicines(String uid) async {
    await saveMedicines(uid, const []);
  }

  static Future<String?> generatePairingCode(String patientId) async {
    _clearServiceError();
    if (!_isReady) return null;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != patientId) return null;

    final rng = Random.secure();
    for (int i = 0; i < 8; i++) {
      final code = (100000 + rng.nextInt(900000)).toString();
      final ref =
          FirebaseFirestore.instance.collection('pairingCodes').doc(code);
      final now = DateTime.now().toUtc();
      final expiry = now.add(const Duration(minutes: 20));
      try {
        await ref.set({
          'code': code,
          'patientId': patientId,
          'createdAt': now,
          'expiresAt': expiry,
          'used': false,
        });
        return code;
      } catch (e) {
        // Retry with a new code if this write fails transiently.
        _setServiceError('Temporary issue while generating pairing code.', e);
      }
    }
    return null;
  }

  static Future<String?> submitPairingRequest(String inviteCode) async {
    _clearServiceError();
    if (!_isReady) return 'Backend is not ready.';
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return 'Please login again and retry.';

    final code = inviteCode.trim();
    if (code.isEmpty) return 'Enter a valid invite code.';

    try {
      final codeRef =
          FirebaseFirestore.instance.collection('pairingCodes').doc(code);
      final codeSnap = await codeRef.get();
      if (!codeSnap.exists || codeSnap.data() == null) {
        return 'Invalid invite code.';
      }

      final data = codeSnap.data()!;
      final patientId = (data['patientId'] ?? '').toString();
      final used = data['used'] == true;
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

      if (patientId.isEmpty) return 'Invite code is invalid.';
      if (patientId == current.uid) return 'You cannot pair your own account.';
      if (used) return 'This invite code has already been used.';
      if (expiresAt != null &&
          DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
        return 'Invite code expired. Ask patient to generate a new one.';
      }

      final reqId = '${patientId}_${current.uid}';
      final currentProfile = await loadUserProfile(current.uid);

      await FirebaseFirestore.instance
          .collection('pairingRequests')
          .doc(reqId)
          .set({
        'requestId': reqId,
        'patientId': patientId,
        'guardianId': current.uid,
        'guardianName': currentProfile?.name ??
            current.email?.split('@').first ??
            'Guardian',
        'guardianEmail': current.email ?? '',
        'code': code,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null;
    } on FirebaseException catch (e) {
      _setServiceError('Could not submit pairing request.', e);
      return 'Could not submit pairing request right now. Please retry.';
    } catch (e) {
      _setServiceError('Unexpected error while submitting pairing request.', e);
      return 'Could not submit pairing request right now. Please retry.';
    }
  }

  static Future<List<Map<String, dynamic>>> loadPendingPairingRequests(
      String patientId) async {
    _clearServiceError();
    if (!_isReady) return const [];
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != patientId) return const [];

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await FirebaseFirestore.instance
          .collection('pairingRequests')
          .where('patientId', isEqualTo: patientId)
          .get();
    } catch (e) {
      _setServiceError('Could not load pending pairing requests.', e);
      return const [];
    }

    final items = snap.docs
        .map((d) => d.data())
        .where((m) => (m['status'] ?? '').toString() == 'pending')
        .toList();

    items.sort((a, b) {
      final ta = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final tb = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return tb.compareTo(ta);
    });
    return items;
  }

  static Future<bool> approvePairingRequest(String requestId) async {
    if (!_isReady) return false;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return false;

    final reqRef =
        FirebaseFirestore.instance.collection('pairingRequests').doc(requestId);
    final reqSnap = await reqRef.get();
    final req = reqSnap.data();
    if (!reqSnap.exists || req == null) return false;

    final patientId = (req['patientId'] ?? '').toString();
    final guardianId = (req['guardianId'] ?? '').toString();
    final status = (req['status'] ?? '').toString();
    if (patientId != current.uid || guardianId.isEmpty || status != 'pending') {
      return false;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .collection('careLinks')
        .doc(guardianId)
        .set({
      'linkId': '${patientId}_$guardianId',
      'patientId': patientId,
      'guardianId': guardianId,
      'status': 'active',
      'permissions': {
        'viewDocuments': true,
        'viewMedicines': true,
        'receiveEmergencyAlerts': true,
        'manageMedicines': false,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await reqRef.set({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': current.uid,
    }, SetOptions(merge: true));

    final code = (req['code'] ?? '').toString();
    if (code.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('pairingCodes')
          .doc(code)
          .set({
        'used': true,
        'usedBy': guardianId,
        'usedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await FirebaseFirestore.instance.collection('users').doc(patientId).set({
      'guardianIds': FieldValue.arrayUnion([guardianId]),
    }, SetOptions(merge: true));

    return true;
  }

  static Future<bool> rejectPairingRequest(String requestId) async {
    if (!_isReady) return false;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return false;

    final reqRef =
        FirebaseFirestore.instance.collection('pairingRequests').doc(requestId);
    final reqSnap = await reqRef.get();
    final req = reqSnap.data();
    if (!reqSnap.exists || req == null) return false;

    final patientId = (req['patientId'] ?? '').toString();
    final status = (req['status'] ?? '').toString();
    if (patientId != current.uid || status != 'pending') return false;

    await reqRef.set({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': current.uid,
    }, SetOptions(merge: true));
    return true;
  }

  static Future<String?> loadLinkedPatientIdForGuardian(
      String guardianId) async {
    if (!_isReady) return null;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != guardianId) return null;

    try {
      final snap = await FirebaseFirestore.instance
          .collectionGroup('careLinks')
          .where('guardianId', isEqualTo: guardianId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return (snap.docs.first.data()['patientId'] ?? '').toString();
      }
    } catch (e) {
      // Fall back to pairing requests lookup below.
      debugPrint(
          'loadPatientIdForGuardian: careLinks query failed, trying pairing requests. Error: $e');
    }

    // Fallback path helps when careLinks query is temporarily unavailable.
    final approvedReqs = await FirebaseFirestore.instance
        .collection('pairingRequests')
        .where('guardianId', isEqualTo: guardianId)
        .where('status', isEqualTo: 'approved')
        .limit(1)
        .get();

    if (approvedReqs.docs.isNotEmpty) {
      return (approvedReqs.docs.first.data()['patientId'] ?? '').toString();
    }

    return null;
  }

  static Future<Map<String, dynamic>?> loadActiveCareLinkForGuardian(
      String guardianId) async {
    if (!_isReady) return null;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != guardianId) return null;

    final snap = await FirebaseFirestore.instance
        .collectionGroup('careLinks')
        .where('guardianId', isEqualTo: guardianId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  static Future<List<Map<String, dynamic>>> loadActiveCareLinksForPatient(
      String patientId) async {
    if (!_isReady) return const [];
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != patientId) return const [];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .collection('careLinks')
        .where('status', isEqualTo: 'active')
        .get();

    final items = snap.docs.map((d) => d.data()).toList();
    items.sort((a, b) {
      final ta = (a['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final tb = (b['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return tb.compareTo(ta);
    });
    return items;
  }

  static Future<List<Map<String, dynamic>>> loadGuardianEmergencyResponses(
      String patientId) async {
    if (!_isReady) return const [];
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return const [];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('guardianResponses')
          .get();

      final items = snap.docs.map((d) {
        final data = d.data();
        return {
          'guardianId': (data['guardianId'] ?? '').toString(),
          'response': (data['response'] ?? '').toString(),
          'etaMinutes':
              data['etaMinutes'] is int ? data['etaMinutes'] as int : null,
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
        };
      }).toList();

      items.sort((a, b) {
        final ta = (a['updatedAt'] as DateTime?) ?? DateTime(1970);
        final tb = (b['updatedAt'] as DateTime?) ?? DateTime(1970);
        return tb.compareTo(ta);
      });

      return items;
    } catch (e) {
      _setServiceError('Failed to load guardian emergency responses.', e);
      return const [];
    }
  }

  static Future<bool> upsertGuardianEmergencyResponse({
    required String patientId,
    required String response,
    int? etaMinutes,
  }) async {
    if (!_isReady) return false;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return false;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('guardianResponses')
          .doc(current.uid)
          .set({
        'guardianId': current.uid,
        'response': response,
        'etaMinutes': etaMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      _setServiceError('Failed to save guardian emergency response.', e);
      return false;
    }
  }

  static Future<void> upsertLiveLocation({
    required String patientId,
    required double latitude,
    required double longitude,
    required DateTime expiresAt,
    bool isSharing = true,
  }) async {
    if (!_isReady) return;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != patientId) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .collection('liveLocation')
        .doc('current')
        .set({
      'patientId': patientId,
      'latitude': latitude,
      'longitude': longitude,
      'isSharing': isSharing,
      'expiresAt': Timestamp.fromDate(expiresAt.toUtc()),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> stopLiveLocation({
    required String patientId,
  }) async {
    if (!_isReady) return;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != patientId) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .collection('liveLocation')
        .doc('current')
        .set({
      'patientId': patientId,
      'isSharing': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> loadLiveLocation({
    required String patientId,
  }) async {
    if (!_isReady) return null;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return null;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('liveLocation')
          .doc('current')
          .get();
      if (!snap.exists || snap.data() == null) return null;
      final data = snap.data()!;
      return {
        'patientId': (data['patientId'] ?? '').toString(),
        'latitude': (data['latitude'] as num?)?.toDouble(),
        'longitude': (data['longitude'] as num?)?.toDouble(),
        'isSharing': data['isSharing'] == true,
        'expiresAt': (data['expiresAt'] as Timestamp?)?.toDate(),
        'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
      };
    } on FirebaseException catch (e) {
      return {
        'isSharing': false,
        'readError': e.code,
        'readErrorMessage': e.message ?? 'Unable to read live location.',
      };
    } catch (_) {
      return {
        'isSharing': false,
        'readError': 'unknown',
        'readErrorMessage': 'Unable to read live location.',
      };
    }
  }

  static Future<bool> updateGuardianPermissions({
    required String patientId,
    required String guardianId,
    required Map<String, bool> permissions,
  }) async {
    if (!_isReady) return false;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != patientId) return false;

    final safePermissions = {
      'viewDocuments': permissions['viewDocuments'] == true,
      'viewMedicines': permissions['viewMedicines'] == true,
      'receiveEmergencyAlerts': permissions['receiveEmergencyAlerts'] == true,
      'manageMedicines': permissions['manageMedicines'] == true,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .collection('careLinks')
        .doc(guardianId)
        .set({
      'permissions': safePermissions,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return true;
  }

  static Future<bool> unlinkGuardianForPatient({
    required String patientId,
    required String guardianId,
  }) async {
    if (!_isReady) return false;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid != patientId) return false;
    if (guardianId.trim().isEmpty) return false;

    final careLinkRef = FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .collection('careLinks')
        .doc(guardianId);

    await careLinkRef.set({
      'status': 'revoked',
      'updatedAt': FieldValue.serverTimestamp(),
      'revokedAt': FieldValue.serverTimestamp(),
      'revokedBy': current.uid,
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('users').doc(patientId).set({
      'guardianIds': FieldValue.arrayRemove([guardianId]),
    }, SetOptions(merge: true));

    return true;
  }

  static String _mapAuthError(String code, [String? message]) {
    final msg = message?.trim() ?? '';
    final upper = msg.toUpperCase();

    switch (code) {
      case 'email-already-in-use':
        return 'This email is already in use. Try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Auth.';
      case 'unknown':
      case 'internal-error':
        if (upper.contains('CONFIGURATION_NOT_FOUND')) {
          return 'Firebase app configuration mismatch. Re-download google-services.json for com.teamtesla.healthvault and reinstall app.';
        }
        if (upper.contains('API_KEY') || upper.contains('API KEY')) {
          return 'Firebase API key/config issue. Re-download google-services.json and rebuild app.';
        }
        return msg.isNotEmpty
            ? 'Authentication failed: $msg'
            : 'Authentication failed (unknown backend error).';
      default:
        return msg.isNotEmpty
            ? 'Authentication failed ($code): $msg'
            : 'Authentication failed ($code).';
    }
  }

  static bool _isConfigurationNotFound(String code, String? message) {
    final msg = (message ?? '').toUpperCase();
    return (code == 'unknown' || code == 'internal-error') &&
        msg.contains('CONFIGURATION_NOT_FOUND');
  }

  static Future<AppUser?> _signUpWithRest({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String accountType,
    int? age,
    String? bloodGroup,
    List<String> conditions = const [],
  }) async {
    final data = await _authRestCall(
      endpoint: 'accounts:signUp',
      payload: {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      },
    );
    if (data == null) return null;

    return AppUser(
      uid: (data['localId'] ?? '').toString(),
      name: name,
      email: (data['email'] ?? email).toString(),
      phone: phone,
      accountType: accountType,
      language: 'English',
      createdAt: DateTime.now(),
      age: age,
      bloodGroup: bloodGroup,
      conditions: conditions,
      emergencyContacts: const [],
    );
  }

  static Future<AppUser?> _signInWithRest({
    required String email,
    required String password,
  }) async {
    final data = await _authRestCall(
      endpoint: 'accounts:signInWithPassword',
      payload: {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      },
    );
    if (data == null) return null;

    return AppUser(
      uid: (data['localId'] ?? '').toString(),
      name: email.split('@').first,
      email: (data['email'] ?? email).toString(),
      phone: '',
      accountType: 'patient',
      language: 'English',
      createdAt: DateTime.now(),
      conditions: const [],
      emergencyContacts: const [],
    );
  }

  static Future<Map<String, dynamic>?> _authRestCall({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    if (!_isReady) return null;
    final apiKey = Firebase.app().options.apiKey;
    if (apiKey.isEmpty) return null;

    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/$endpoint?key=$apiKey',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        _lastAuthError = null;
        return json;
      }

      final msg = (json['error']?['message'] ?? '').toString();
      _lastAuthError = _mapRestAuthError(msg);
      return null;
    } catch (_) {
      _lastAuthError = 'Unable to reach auth service. Please try again.';
      return null;
    }
  }

  static String _mapRestAuthError(String message) {
    switch (message) {
      case 'EMAIL_EXISTS':
        return 'This email is already in use. Try logging in instead.';
      case 'INVALID_EMAIL':
        return 'Please enter a valid email address.';
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
      case 'WEAK_PASSWORD':
        return 'Password is too weak. Use at least 6 characters.';
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_PASSWORD':
        return 'Invalid email or password.';
      case 'CONFIGURATION_NOT_FOUND':
        return 'Firebase auth configuration is still not active. Please wait 2-5 minutes and retry.';
      default:
        return 'Authentication failed: $message';
    }
  }
}
