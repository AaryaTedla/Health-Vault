import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';
import 'audit_service.dart';

/// Voice Agent Service - Handles speech-to-text, intent recognition, and text-to-speech
/// State machine: idle -> listening -> transcribing -> confirming -> executing -> speaking -> idle
class VoiceAgentService extends ChangeNotifier {
  // Core dependencies
  late final stt.SpeechToText _speechToText;
  late final FlutterTts _textToSpeech;

  // Voice state tracking
  VoiceState _currentState = VoiceState.idle;
  VoiceSession? _activeSession;
  String _currentLanguage = 'en'; // 'en' or 'hi'

  // Configuration
  static const int _stTimeout = 30000; // 30 seconds for STT
  static const int _ttsTimeout = 10000; // 10 seconds for TTS
  static const double _confidenceThreshold = 0.6;

  // Timers
  Timer? _stTimeoutTimer;
  Timer? _ttsTimeoutTimer;

  // Callbacks
  VoidCallback? onStateChanged;
  Function(String transcript, double confidence)? onTranscript;
  Function(VoiceSession session)? onSessionComplete;
  Function(String error)? onError;

  VoiceAgentService() {
    _speechToText = stt.SpeechToText();
    _textToSpeech = FlutterTts();
    _initializeTTS();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Getters
  VoiceState get currentState => _currentState;
  VoiceSession? get activeSession => _activeSession;
  String get currentLanguage => _currentLanguage;
  bool get isListening => _currentState == VoiceState.listening;
  bool get isInitialized => _speechToText.isAvailable;

  // ───────────────────────────────────────────────────────────────────────────
  // Initialization
  Future<void> initialize() async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission.isDenied) {
        _onError(
            'Microphone permission denied. Please enable in app settings.');
        notifyListeners();
        return;
      }
      if (micPermission.isPermanentlyDenied) {
        _onError(
            'Microphone permission permanently denied. Please enable in app settings.');
        openAppSettings();
        notifyListeners();
        return;
      }

      // Initialize STT
      final available = await _speechToText.initialize(
        onError: _handleSTTError,
        onStatus: _handleSTTStatus,
        debugLogging: kDebugMode,
      );
      if (!available) {
        _onError(
            'Speech-to-text not available on this device. Please check your device supports voice input.');
      }
      notifyListeners();
    } catch (e) {
      _onError('Failed to initialize voice service: $e');
    }
  }

  void _initializeTTS() {
    // Natural speech for elderly users - slower pace, clear articulation
    _textToSpeech.setVolume(1.0);
    _textToSpeech.setSpeechRate(0.75); // Natural pace (0.5-1.0, lower = slower)
    _textToSpeech.setPitch(0.95); // Slightly lower pitch for warmth

    // Set language-specific voice settings for natural speech
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Use best available voice for language
      _textToSpeech.setLanguage(_currentLanguage == 'hi' ? 'hi-IN' : 'en-US');
      _textToSpeech.speak(''); // Prime TTS engine
      _textToSpeech.setLanguage(_currentLanguage == 'hi' ? 'hi-IN' : 'en-US');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Public Voice Actions
  Future<void> startListening() async {
    if (_currentState != VoiceState.idle) {
      _onError('Voice already active. Please wait or cancel.');
      return;
    }

    if (!_speechToText.isAvailable) {
      _onError('Microphone not available.');
      return;
    }

    // Create new session
    _activeSession = VoiceSession(
      id: const Uuid().v4(),
      language: _currentLanguage,
      state: VoiceState.listening,
      startedAt: DateTime.now(),
    );

    _setVoiceState(VoiceState.listening);

    try {
      await _speechToText.listen(
        onResult: _handleSTTResult,
        localeId: _currentLanguage == 'hi' ? 'hi_IN' : 'en_US',
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );

      // Set timeout
      _stTimeoutTimer = Timer(Duration(milliseconds: _stTimeout), () {
        if (_currentState == VoiceState.listening ||
            _currentState == VoiceState.transcribing) {
          _onVoiceTimeout('No speech detected.');
        }
      });
    } catch (e) {
      _onError('Failed to start listening: $e');
      _resetSession();
    }
  }

  Future<void> stopListening() async {
    _stTimeoutTimer?.cancel();
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  Future<void> cancelVoiceSession() async {
    _stTimeoutTimer?.cancel();
    _ttsTimeoutTimer?.cancel();
    await stopListening();
    try {
      await _textToSpeech.stop();
    } catch (_) {
      // Ignore stop errors
    }
    _resetSession();
  }

  Future<void> setLanguage(String language) async {
    if (language != 'en' && language != 'hi') {
      _onError('Unsupported language. Use "en" or "hi".');
      return;
    }
    _currentLanguage = language;
    await _textToSpeech.setLanguage(language == 'hi' ? 'hi_IN' : 'en_US');
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Internal: STT Handlers
  void _handleSTTResult(dynamic result) {
    if (!isActive) return;

    // Handle different speech_to_text versions gracefully
    try {
      final transcript = result.recognizedWords as String? ?? '';
      final isFinal = result.finalResult as bool? ?? false;
      final confidence = (result.confidence as num?)?.toDouble() ?? 0.0;

      if (isFinal && transcript.isNotEmpty) {
        _stTimeoutTimer?.cancel();
        _setVoiceState(VoiceState.transcribing);

        // Update session
        _activeSession = _activeSession?.copyWith(
          transcript: transcript,
          state: VoiceState.transcribing,
          confidence: confidence,
        );

        // Call callback
        onTranscript?.call(transcript, confidence);

        // Move to confirming state
        _setVoiceState(VoiceState.confirming);
      } else if (transcript.isNotEmpty) {
        // Partial result
        onTranscript?.call(transcript, confidence);
      }
    } catch (e) {
      debugPrint('Error handling STT result: $e');
    }
  }

  void _handleSTTError(dynamic error) {
    try {
      final errorMsg = error.errorMsg as String? ?? error.toString();
      debugPrint('STT Error: $errorMsg');

      if (errorMsg.contains('no_match')) {
        _onVoiceError(
            VoiceOutcome.noSpeech, 'No speech detected. Please try again.');
      } else if (errorMsg.contains('permission')) {
        _onVoiceError(VoiceOutcome.micDenied, 'Microphone permission denied.');
      } else {
        _onVoiceError(
            VoiceOutcome.stsFailed, 'Transcription failed: $errorMsg');
      }
    } catch (e) {
      _onError('STT Error: $e');
    }
  }

  void _handleSTTStatus(String status) {
    debugPrint('STT Status: $status');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Public: Text-to-Speech
  Future<void> speak(String text) async {
    if (_currentState != VoiceState.executing &&
        _currentState != VoiceState.confirming) {
      return; // Only speak at appropriate times
    }

    _setVoiceState(VoiceState.speaking);

    try {
      await _textToSpeech.speak(text);

      _ttsTimeoutTimer = Timer(Duration(milliseconds: _ttsTimeout), () {
        if (_currentState == VoiceState.speaking) {
          debugPrint('TTS timeout');
          _resetSession();
        }
      });

      // Wait for TTS to complete (estimate based on text length)
      final estimatedDuration = (text.length / 10) * 1000; // rough estimate
      await Future.delayed(Duration(milliseconds: estimatedDuration.toInt()));

      _resetSession();
    } catch (e) {
      _onVoiceError(VoiceOutcome.ttsFailed, 'Text-to-speech failed: $e');
    } finally {
      _ttsTimeoutTimer?.cancel();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Internal: Session Management
  void _setVoiceState(VoiceState newState) {
    if (_currentState == newState) return;
    _currentState = newState;
    _activeSession = _activeSession?.copyWith(state: newState);
    notifyListeners();
    onStateChanged?.call();
  }

  void _onVoiceTimeout(String message) {
    _onVoiceError(VoiceOutcome.timeout, message);
  }

  void _onVoiceError(VoiceOutcome outcome, String message) {
    _activeSession = _activeSession?.copyWith(
      outcome: outcome,
      errorMessage: message,
      endedAt: DateTime.now(),
      state: VoiceState.error,
    );
    _setVoiceState(VoiceState.error);
    _onError(message);

    // Log to audit
    AuditService.logVoiceAction(
      action: 'voice_error',
      details: {
        'outcome': outcome.toString(),
        'message': message,
        'session_id': _activeSession?.id,
      },
    );

    // Reset after a delay
    Future.delayed(const Duration(seconds: 2), _resetSession);
  }

  void _onError(String message) {
    debugPrint('VoiceAgentService error: $message');
    onError?.call(message);
  }

  void _resetSession() {
    if (_activeSession != null && _activeSession!.endedAt == null) {
      _activeSession = _activeSession?.copyWith(
        endedAt: DateTime.now(),
        outcome: _activeSession!.outcome ?? VoiceOutcome.cancelled,
      );

      // Log session completion
      onSessionComplete?.call(_activeSession!);

      AuditService.logVoiceAction(
        action: 'voice_session_complete',
        details: {
          'session_id': _activeSession!.id,
          'duration_ms': _activeSession!.duration?.inMilliseconds,
          'outcome': _activeSession!.outcome.toString(),
          'transcript': _activeSession!.transcript,
          'confidence': _activeSession!.confidence,
        },
      );
    }

    _activeSession = null;
    _setVoiceState(VoiceState.idle);
  }

  bool get isActive => _activeSession != null && _activeSession!.isActive;

  @override
  void dispose() {
    _stTimeoutTimer?.cancel();
    _ttsTimeoutTimer?.cancel();
    _speechToText.stop();
    _textToSpeech.stop();
    super.dispose();
  }
}

/// Helper extension for copying VoiceSession with changes
extension VoiceSessionCopy on VoiceSession {
  VoiceSession copyWith({
    String? id,
    String? language,
    VoiceState? state,
    String? transcript,
    VoiceIntentType? intent,
    double? confidence,
    DateTime? startedAt,
    DateTime? endedAt,
    VoiceOutcome? outcome,
    String? errorMessage,
    Map<String, dynamic>? actionParams,
  }) {
    return VoiceSession(
      id: id ?? this.id,
      language: language ?? this.language,
      state: state ?? this.state,
      transcript: transcript ?? this.transcript,
      intent: intent ?? this.intent,
      confidence: confidence ?? this.confidence,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      outcome: outcome ?? this.outcome,
      errorMessage: errorMessage ?? this.errorMessage,
      actionParams: actionParams ?? this.actionParams,
    );
  }
}
