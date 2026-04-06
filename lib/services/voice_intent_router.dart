import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'app_state.dart';
import 'audit_service.dart';
import 'ai_service.dart';
import 'voice_intents_en_hi.dart';

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
      final catalogIntent = _parseFromCatalog(transcript, language);
      if (catalogIntent != null) {
        final (intent, params) = catalogIntent;
        if (highRiskActions.contains(intent)) {
          return VoiceIntentResult(
            intent: intent,
            recognized: true,
            requiresConfirmation: true,
            params: params,
            reason: _getConfirmationPrompt(intent, params),
          );
        }
        return await _executeIntent(intent, params);
      }

      final (keywordIntent, keywordParams) = _parseIntent(transcript, language);
      if (keywordIntent != VoiceIntentType.unknown) {
        if (highRiskActions.contains(keywordIntent)) {
          return VoiceIntentResult(
            intent: keywordIntent,
            recognized: true,
            requiresConfirmation: true,
            params: keywordParams,
            reason: _getConfirmationPrompt(keywordIntent, keywordParams),
          );
        }
        return await _executeIntent(keywordIntent, keywordParams);
      }

      // Step 1: Use AI to understand the voice command
      final aiUnderstanding = await AIService.understandVoiceCommand(
        transcript: transcript,
        language: language,
      );

      // Step 2: Map AI understanding to our intent types
      final intent = _mapAIIntentToVoiceIntent(aiUnderstanding['intent']);
      final understood = aiUnderstanding['understood'] as bool;
      final aiConfidence = aiUnderstanding['confidence'] as double;
      final clarification = aiUnderstanding['clarification'] as String;

      if (!understood || intent == VoiceIntentType.unknown) {
        // AI couldn't understand - try keyword fallback
        final (fallbackIntent, fallbackParams) =
            _parseIntent(transcript, language);

        if (fallbackIntent != VoiceIntentType.unknown) {
          // Keyword matching worked
          return await _executeIntent(fallbackIntent, fallbackParams);
        }

        // Neither AI nor keywords understood
        return VoiceIntentResult(
          intent: VoiceIntentType.unknown,
          recognized: false,
          reason: clarification.isNotEmpty
              ? clarification
              : 'I didn\'t understand that. Could you try again with: medicines, appointments, documents, or chat?',
        );
      }

      // Extract action from AI response
      final action = aiUnderstanding['action'] as String? ?? '';
      final params = _extractParams(intent, action);

      // Check if high-risk action
      if (highRiskActions.contains(intent)) {
        return VoiceIntentResult(
          intent: intent,
          recognized: true,
          requiresConfirmation: true,
          params: params,
          reason: _getConfirmationPrompt(intent, params),
        );
      }

      // Execute action
      return await _executeIntent(intent, params);
    } catch (e) {
      debugPrint('Error processing voice command: $e');
      return VoiceIntentResult(
        intent: VoiceIntentType.unknown,
        recognized: false,
        reason: 'I had trouble processing that. Please try again.',
      );
    }
  }

  /// Map AI intent strings to our VoiceIntentType enum
  VoiceIntentType _mapAIIntentToVoiceIntent(String aiIntent) {
    switch (aiIntent.toLowerCase()) {
      case 'navigate':
        return VoiceIntentType.navigate;
      case 'medicine':
        return VoiceIntentType.medicine;
      case 'appointment':
        return VoiceIntentType.appointment;
      case 'document':
        return VoiceIntentType.document;
      case 'emergency':
        return VoiceIntentType.emergency;
      case 'chat':
        return VoiceIntentType.navigate; // Chat is handled as navigate target
      case 'profile':
        return VoiceIntentType.profile;
      case 'guardian':
        return VoiceIntentType.guardian;
      case 'help':
        return VoiceIntentType.help;
      default:
        return VoiceIntentType.unknown;
    }
  }

  /// Extract params from AI action string
  Map<String, dynamic> _extractParams(VoiceIntentType intent, String action) {
    switch (intent) {
      case VoiceIntentType.navigate:
        return {'target': action == 'chat' ? 'ai_chat' : action};
      case VoiceIntentType.medicine:
        return {'action': action.isEmpty ? 'list' : action};
      case VoiceIntentType.appointment:
        return {'action': action.isEmpty ? 'list' : action};
      case VoiceIntentType.document:
        return {'action': action.isEmpty ? 'list' : action};
      case VoiceIntentType.emergency:
        return {'action': 'trigger'};
      case VoiceIntentType.profile:
        return {'action': 'view'};
      case VoiceIntentType.guardian:
        return {'action': 'status'};
      case VoiceIntentType.help:
        return {'action': 'guide'};
      default:
        return {};
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

  (VoiceIntentType, Map<String, dynamic>)? _parseFromCatalog(
    String transcript,
    String language,
  ) {
    final lower = transcript.toLowerCase().trim();
    final lang = language == 'hi' ? 'hi' : 'en';

    bool matches(List<String> phrases) =>
        VoiceIntentPhrases.matchesPhrase(lower, phrases);

    if (matches(VoiceIntentPhrases.helpPhrases[lang] ?? const [])) {
      return (VoiceIntentType.help, {'action': 'guide'});
    }

    if (matches(VoiceIntentPhrases.emergencyPhrases[lang]?['trigger'] ?? const [])) {
      return (VoiceIntentType.emergency, {'action': 'trigger'});
    }

    if (matches(VoiceIntentPhrases.navigationPhrases[lang]?['medicines'] ?? const [])) {
      return (VoiceIntentType.medicine, {'action': 'list'});
    }
    if (matches(VoiceIntentPhrases.medicinePhrases[lang]?['next_dose'] ?? const [])) {
      return (VoiceIntentType.medicine, {'action': 'next_dose'});
    }
    if (matches(VoiceIntentPhrases.medicinePhrases[lang]?['mark_taken'] ?? const [])) {
      return (VoiceIntentType.medicine, {'action': 'mark_taken'});
    }
    if (matches(VoiceIntentPhrases.medicinePhrases[lang]?['add_reminder'] ?? const [])) {
      return (VoiceIntentType.medicine, {'action': 'add_reminder'});
    }

    if (matches(VoiceIntentPhrases.navigationPhrases[lang]?['appointments'] ?? const []) ||
        matches(VoiceIntentPhrases.appointmentPhrases[lang]?['list'] ?? const [])) {
      return (VoiceIntentType.appointment, {'action': 'list'});
    }
    if (matches(VoiceIntentPhrases.appointmentPhrases[lang]?['add'] ?? const [])) {
      return (VoiceIntentType.appointment, {'action': 'add'});
    }

    if (matches(VoiceIntentPhrases.navigationPhrases[lang]?['documents'] ?? const []) ||
        matches(VoiceIntentPhrases.documentPhrases[lang]?['list'] ?? const [])) {
      return (VoiceIntentType.document, {'action': 'list'});
    }
    if (matches(VoiceIntentPhrases.documentPhrases[lang]?['open'] ?? const [])) {
      return (VoiceIntentType.document, {'action': 'open'});
    }

    if (matches(VoiceIntentPhrases.navigationPhrases[lang]?['chat'] ?? const [])) {
      return (VoiceIntentType.navigate, {'target': 'ai_chat'});
    }

    if (matches(VoiceIntentPhrases.navigationPhrases[lang]?['guardian'] ?? const []) ||
        matches(VoiceIntentPhrases.guardianPhrases[lang]?['status'] ?? const [])) {
      return (VoiceIntentType.guardian, {'action': 'status'});
    }

    if (matches(VoiceIntentPhrases.navigationPhrases[lang]?['profile'] ?? const [])) {
      return (VoiceIntentType.profile, {'action': 'view'});
    }

    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Intent parsing and NLP (simplified keyword matching)
  (VoiceIntentType, Map<String, dynamic>) _parseIntent(
    String transcript,
    String language,
  ) {
    final lower = transcript.toLowerCase().trim();
    final lang = language == 'hi' ? 'hi' : 'en';

    if (VoiceIntentPhrases.matchesPhrase(
      lower,
      VoiceIntentPhrases.helpPhrases[lang] ?? const [],
    )) {
      return (VoiceIntentType.help, {'action': 'guide'});
    }

    final phrases = VoiceIntentPhrases.getPhrasesForLanguage(lang);

    bool matchesCatalog(List<String> words) =>
        VoiceIntentPhrases.matchesPhrase(lower, words);

    if (matchesCatalog(phrases['navigation']?['medicines'] ?? const [])) {
      return (VoiceIntentType.medicine, {'action': 'list'});
    }
    if (matchesCatalog(phrases['navigation']?['appointments'] ?? const []) ||
        matchesCatalog(phrases['appointment']?['list'] ?? const [])) {
      return (VoiceIntentType.appointment, {'action': 'list'});
    }
    if (matchesCatalog(phrases['navigation']?['documents'] ?? const []) ||
        matchesCatalog(phrases['document']?['list'] ?? const [])) {
      return (VoiceIntentType.document, {'action': 'list'});
    }
    if (matchesCatalog(phrases['navigation']?['chat'] ?? const [])) {
      return (VoiceIntentType.navigate, {'target': 'ai_chat'});
    }
    if (matchesCatalog(phrases['navigation']?['emergency'] ?? const []) ||
        matchesCatalog(phrases['emergency']?['trigger'] ?? const [])) {
      return (VoiceIntentType.emergency, {'action': 'trigger'});
    }
    if (matchesCatalog(phrases['navigation']?['guardian'] ?? const []) ||
        matchesCatalog(phrases['guardian']?['status'] ?? const [])) {
      return (VoiceIntentType.guardian, {'action': 'status'});
    }
    if (matchesCatalog(phrases['navigation']?['profile'] ?? const [])) {
      return (VoiceIntentType.profile, {'action': 'view'});
    }

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

        case VoiceIntentType.help:
          return _handleHelp(params);

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

  VoiceIntentResult _handleHelp(Map<String, dynamic> params) {
    AuditService.logVoiceAction(
      action: 'voice_help_opened',
      details: {'action': params['action'] ?? 'guide'},
    );

    return VoiceIntentResult(
      intent: VoiceIntentType.help,
      recognized: true,
      executed: true,
      reason: 'Opening voice command guide.',
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
