import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_service.dart';

class AuditService {
  static Future<void> logEvent({
    required String ownerUserId,
    required String event,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (!FirebaseService.isReady) return;
    if (ownerUserId.trim().isEmpty) return;

    final actor = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUserId)
          .collection('auditLogs')
          .add({
        'event': event,
        'ownerUserId': ownerUserId,
        'actorUid': actor?.uid,
        'actorEmail': actor?.email,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Keep app flow uninterrupted even if audit logging fails.
    }
  }

  static Future<List<Map<String, dynamic>>> loadRecentLogs({
    required String ownerUserId,
    int limit = 50,
  }) async {
    if (!FirebaseService.isReady) return const [];
    if (ownerUserId.trim().isEmpty) return const [];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUserId)
          .collection('auditLogs')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Log voice-related actions and sessions
  static Future<void> logVoiceAction({
    required String action,
    Map<String, dynamic> details = const {},
  }) async {
    if (!FirebaseService.isReady) return;

    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(actor.uid)
          .collection('voiceAuditLogs')
          .add({
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'ownerUserId': actor.uid,
      });
    } catch (_) {
      // Keep app flow uninterrupted even if voice audit logging fails
    }
  }
}
