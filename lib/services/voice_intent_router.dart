import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'app_state.dart';
import 'audit_service.dart';

/// Voice Intent Router - Maps voice commands to app actions
/// Handles intent recognition, parameter extraction, and action execution
class VoiceIntentRouter {
  final AppState appState;

  VoiceIntentRouter({required this.appState});

  // High-risk actions require explicit confirmation
  static const highRiskActions = {
    VoiceIntentType.emergency,
    // Medicine dosage changes would also be high-risk
  };

  // ───────────────────────────────────────────────────────────────────────────
  // Main entry point: Process voice transcript -> Execute action
  Future<VoiceIntentResult> processVoiceCommand({
    required String transcript,
    required String language,
    required double confidence,
  }) async {
    try {
      // Step 1: Recognize intent and extract parameters
      final (intent, params) = _parseIntent(transcript, language);

      if (intent == VoiceIntentType.unknown) {
        return VoiceIntentResult(
          intent: intent,
          recognized: false,
          reason: 'Command not recognized. Please try again.',
        );
      }

      // Step 2: Check if high-risk action
      if (highRiskActions.contains(intent)) {
        return VoiceIntentResult(
          intent: intent,
          recognized: true,
          requiresConfirmation: true,
          params: params,
          reason: _getConfirmationPrompt(intent, params),
        );
      }

      // Step 3: Execute action
      return await _executeIntent(intent, params);
    } catch (e) {
      debugPrint('Error processing voice command: $e');
      return VoiceIntentResult(
        intent: VoiceIntentType.unknown,
        recognized: false,
        reason: 'Failed to process command: $e',
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Confirmation handling for high-risk actions
  Future<VoiceIntentResult> confirmAndExecute(
    VoiceIntentResult pendingIntent, {
    required bool confirmed,
  }) async {
    if (!confirmed) {
      AuditService.logVoiceAction(
        action: 'voice_command_cancelled',
        details: {
          'intent': pendingIntent.intent.toString(),
          'reason': 'User declined confirmation',
        },
      );
      return VoiceIntentResult(
        intent: pendingIntent.intent,
        recognized: true,
        requiresConfirmation: true,
        reason: 'Action cancelled.',
      );
    }

    return await _executeIntent(
        pendingIntent.intent, pendingIntent.params ?? {});
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Intent parsing and NLP (simplified keyword matching)
  (VoiceIntentType, Map<String, dynamic>) _parseIntent(
    String transcript,
    String language,
  ) {
    final lower = transcript.toLowerCase().trim();

    // Navigation intents
    if (_matchesKeywords(lower, ['show', 'open', 'go to'],
        ['medicines', 'medication', 'meds'])) {
      return (VoiceIntentType.medicine, {'action': 'list'});
    }
    if (_matchesKeywords(
        lower, ['show', 'open'], ['appointments', 'doctor', 'clinic'])) {
      return (VoiceIntentType.appointment, {'action': 'list'});
    }
    if (_matchesKeywords(lower, ['show', 'open'],
        ['documents', 'files', 'docs', 'medical records'])) {
      return (VoiceIntentType.document, {'action': 'list'});
    }
    if (_matchesKeywords(
        lower, ['show', 'open'], ['chat', 'ai', 'chat with doctor'])) {
      return (VoiceIntentType.navigate, {'target': 'ai_chat'});
    }
    if (_matchesKeywords(lower, ['show', 'open'], ['emergency'])) {
      return (VoiceIntentType.emergency, {'action': 'show'});
    }
    if (_matchesKeywords(lower, ['show', 'open'], ['guardian', 'caregiver'])) {
      return (VoiceIntentType.guardian, {'action': 'status'});
    }
    if (_matchesKeywords(
        lower, ['show', 'open', 'go'], ['profile', 'account', 'settings'])) {
      return (VoiceIntentType.profile, {'action': 'view'});
    }

    // Medicine actions
    if (_matchesKeywords(lower, ['list', 'show'],
        ['next dose', 'upcoming medicine', 'next medicine'])) {
      return (VoiceIntentType.medicine, {'action': 'next_dose'});
    }
    if (_matchesKeywords(
        lower, ['mark', 'take'], ['medicine', 'medication', 'dose', 'pill'])) {
      return (VoiceIntentType.medicine, {'action': 'mark_taken'});
    }
    if (_matchesKeywords(
        lower, ['add', 'set'], ['reminder', 'alert', 'notification'])) {
      return (VoiceIntentType.medicine, {'action': 'add_reminder'});
    }

    // Appointment actions
    if (_matchesKeywords(lower, ['list', 'show'],
        ['upcoming appointments', 'next appointment'])) {
      return (VoiceIntentType.appointment, {'action': 'list_upcoming'});
    }
    if (_matchesKeywords(lower, ['add', 'book', 'schedule'],
        ['appointment', 'doctor', 'clinic'])) {
      return (VoiceIntentType.appointment, {'action': 'add'});
    }

    // Document actions
    if (_matchesKeywords(
        lower, ['list', 'show'], ['recent documents', 'latest documents'])) {
      return (VoiceIntentType.document, {'action': 'list_recent'});
    }

    // Guardian actions
    if (_matchesKeywords(
        lower, ['show', 'check'], ['guardian status', 'caregiver status'])) {
      return (VoiceIntentType.guardian, {'action': 'status'});
    }

    // Emergency (high-risk)
    if (_matchesKeywords(lower, ['emergency', 'help', 'urgent'],
        ['emergency', 'help', 'urgent', 'sos', 'danger'])) {
      return (VoiceIntentType.emergency, {'action': 'trigger'});
    }

    return (VoiceIntentType.unknown, {});
  }

  bool _matchesKeywords(
    String input,
    List<String> actionWords,
    List<String> objectWords,
  ) {
    final hasAction = actionWords.any((word) => input.contains(word));
    final hasObject = objectWords.any((word) => input.contains(word));
    return hasAction && hasObject;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Action execution
  Future<VoiceIntentResult> _executeIntent(
    VoiceIntentType intent,
    Map<String, dynamic> params,
  ) async {
    try {
      switch (intent) {
        case VoiceIntentType.navigate:
          return _handleNavigate(params);

        case VoiceIntentType.medicine:
          return _handleMedicineAction(params);

        case VoiceIntentType.appointment:
          return _handleAppointmentAction(params);

        case VoiceIntentType.document:
          return _handleDocumentAction(params);

        case VoiceIntentType.emergency:
          return _handleEmergency(params);

        case VoiceIntentType.guardian:
          return _handleGuardianAction(params);

        case VoiceIntentType.profile:
          return _handleProfileAction(params);

        case VoiceIntentType.unknown:
          return VoiceIntentResult(
            intent: intent,
            recognized: false,
            reason: 'Unknown command.',
          );
      }
    } catch (e) {
      debugPrint('Error executing voice intent: $e');
      return VoiceIntentResult(
        intent: intent,
        recognized: true,
        reason: 'Failed to execute action: $e',
      );
    }
  }

  VoiceIntentResult _handleNavigate(Map<String, dynamic> params) {
    final target = params['target'] as String?;
    return VoiceIntentResult(
      intent: VoiceIntentType.navigate,
      recognized: true,
      executed: true,
      reason: 'Opening $target',
      params: {'screen': target},
    );
  }

  VoiceIntentResult _handleMedicineAction(Map<String, dynamic> params) {
    final action = params['action'] as String?;
    final numMedicines = appState.medicines.length;

    String reason;
    switch (action) {
      case 'list':
        reason = numMedicines > 0
            ? 'Found $numMedicines medicines.'
            : 'No medicines found.';
        break;
      case 'next_dose':
        reason = 'Showing next dose information.';
        break;
      case 'mark_taken':
        reason = 'Marking medicine as taken. Please confirm which medicine.';
        break;
      case 'add_reminder':
        reason = 'Adding new reminder. Please provide details.';
        break;
      default:
        reason = 'Medicine action: $action';
    }

    AuditService.logVoiceAction(
      action: 'voice_medicine_action',
      details: {'action': action, 'medicine_count': numMedicines},
    );

    return VoiceIntentResult(
      intent: VoiceIntentType.medicine,
      recognized: true,
      executed: true,
      reason: reason,
      params: params,
    );
  }

  VoiceIntentResult _handleAppointmentAction(Map<String, dynamic> params) {
    final action = params['action'] as String?;
    final numAppointments = appState.appointments.length;

    String reason;
    switch (action) {
      case 'list':
      case 'list_upcoming':
        reason = numAppointments > 0
            ? 'Found $numAppointments upcoming appointments.'
            : 'No appointments scheduled.';
        break;
      case 'add':
        reason = 'Adding new appointment. Please provide details.';
        break;
      default:
        reason = 'Appointment action: $action';
    }

    AuditService.logVoiceAction(
      action: 'voice_appointment_action',
      details: {'action': action, 'appointment_count': numAppointments},
    );

    return VoiceIntentResult(
      intent: VoiceIntentType.appointment,
      recognized: true,
      executed: true,
      reason: reason,
      params: params,
    );
  }

  VoiceIntentResult _handleDocumentAction(Map<String, dynamic> params) {
    final action = params['action'] as String?;
    final numDocs = appState.documents.length;

    String reason;
    switch (action) {
      case 'list':
      case 'list_recent':
        reason = numDocs > 0
            ? 'Found $numDocs documents.'
            : 'No documents available.';
        break;
      default:
        reason = 'Document action: $action';
    }

    AuditService.logVoiceAction(
      action: 'voice_document_action',
      details: {'action': action, 'document_count': numDocs},
    );

    return VoiceIntentResult(
      intent: VoiceIntentType.document,
      recognized: true,
      executed: true,
      reason: reason,
      params: params,
    );
  }

  VoiceIntentResult _handleEmergency(Map<String, dynamic> params) {
    final action = params['action'] as String?;

    AuditService.logVoiceAction(
      action: 'voice_emergency_triggered',
      details: {
        'action': action,
        'timestamp': DateTime.now().toIso8601String()
      },
    );

    return VoiceIntentResult(
      intent: VoiceIntentType.emergency,
      recognized: true,
      executed: true,
      reason: 'Emergency mode activated. Notifying guardians.',
      params: params,
    );
  }

  VoiceIntentResult _handleGuardianAction(Map<String, dynamic> params) {
    final action = params['action'] as String?;
    final numGuardians = appState.linkedGuardians.length;

    String reason;
    switch (action) {
      case 'status':
        reason = numGuardians > 0
            ? 'Showing $numGuardians guardian statuses.'
            : 'No guardians linked.';
        break;
      default:
        reason = 'Guardian action: $action';
    }

    AuditService.logVoiceAction(
      action: 'voice_guardian_action',
      details: {'action': action, 'guardian_count': numGuardians},
    );

    return VoiceIntentResult(
      intent: VoiceIntentType.guardian,
      recognized: true,
      executed: true,
      reason: reason,
      params: params,
    );
  }

  VoiceIntentResult _handleProfileAction(Map<String, dynamic> params) {
    final action = params['action'] as String?;
    final userName = appState.currentUser?.name ?? 'User';

    String reason;
    switch (action) {
      case 'view':
        reason = 'Showing profile for $userName.';
        break;
      default:
        reason = 'Profile action: $action';
    }

    AuditService.logVoiceAction(
      action: 'voice_profile_action',
      details: {'action': action, 'user': userName},
    );

    return VoiceIntentResult(
      intent: VoiceIntentType.profile,
      recognized: true,
      executed: true,
      reason: reason,
      params: params,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helper: Confirmation prompts
  String _getConfirmationPrompt(
      VoiceIntentType intent, Map<String, dynamic> params) {
    switch (intent) {
      case VoiceIntentType.emergency:
        return 'Are you sure you want to trigger emergency mode? Say yes to confirm.';
      default:
        return 'Do you want to proceed? Say yes to confirm.';
    }
  }
}

/// Result from voice intent processing
class VoiceIntentResult {
  final VoiceIntentType intent;
  final bool recognized;
  final bool executed;
  final bool requiresConfirmation;
  final String? reason;
  final Map<String, dynamic>? params;

  VoiceIntentResult({
    required this.intent,
    required this.recognized,
    this.executed = false,
    this.requiresConfirmation = false,
    this.reason,
    this.params,
  });

  @override
  String toString() =>
      'VoiceIntentResult(intent: $intent, recognized: $recognized, executed: $executed, requiresConfirmation: $requiresConfirmation, reason: $reason)';
}
