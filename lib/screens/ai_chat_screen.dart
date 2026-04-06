import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/app_state.dart';
import '../services/ai_service.dart';
import '../services/voice_agent_service.dart';
import '../services/localization_service.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});
  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  late FlutterTts _tts;
  bool _isSending = false;
  bool _isInputFocused = false;
  String _aiRouteNote = 'Ready';

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '0',
      content: 'Hello! I am your HealthVault companion 😊\n\n'
          'I can help you:\n'
          '• Understand your medical reports in simple language\n'
          '• Explain what your symptoms might mean\n'
          '• Answer questions about medicines\n'
          '• Guide you on when to see a doctor\n\n'
          'How are you feeling today?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  final List<String> _quickQuestions = [
    'I feel dizzy 😵',
    'I have chest pain 💔',
    'I have high fever 🌡️',
    'My BP is high',
    'I cannot sleep',
    'I feel very tired',
    'I have knee pain',
    'What is HbA1c?',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onInputFocusChanged);
    _initTTS();
  }

  void _initTTS() {
    _tts = FlutterTts();
    _tts.setSpeechRate(0.75); // Natural pace for elderly
    _tts.setPitch(0.95); // Warm, friendly tone
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onInputFocusChanged);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _tts.stop();
    super.dispose();
  }

  void _onInputFocusChanged() {
    if (!mounted) return;
    final next = _focusNode.hasFocus;
    if (next == _isInputFocused) return;
    setState(() => _isInputFocused = next);
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final showQuickQuestions =
        _messages.length <= 2 && !_isInputFocused && !isKeyboardOpen;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C3483), Color(0xFF9B59B6)]),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28))),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(children: [
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.smart_toy_rounded,
                          color: Colors.white, size: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('AI Health Assistant',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text(_aiRouteNote,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ])),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.circle, color: _providerColor(), size: 8),
                        SizedBox(width: 5),
                        Text(_providerLabel(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ])),
                ]),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: const DisclaimerBox(text: AppConstants.chatDisclaimer),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _ChatBubble(message: _messages[i]),
            ),
          ),

          // Quick questions
          if (showQuickQuestions)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick questions:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickQuestions
                        .map((q) => GestureDetector(
                              onTap: () => _sendMessage(q),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF9B59B6)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFF9B59B6)
                                            .withValues(alpha: 0.3))),
                                child: Text(q,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6C3483),
                                        fontWeight: FontWeight.w500)),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          // Input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: isKeyboardOpen
                  ? null
                  : const Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  focusNode: _focusNode,
                  style: const TextStyle(
                      fontSize: 15, color: AppTheme.textPrimary),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isSending,
                  decoration: InputDecoration(
                    hintText: 'Describe how you feel...',
                    hintStyle:
                        const TextStyle(color: AppTheme.textHint, fontSize: 14),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: Color(0xFF9B59B6), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isSending ? null : () => _sendMessage(_msgCtrl.text),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: _isSending
                            ? AppTheme.textHint
                            : const Color(0xFF9B59B6),
                        shape: BoxShape.circle),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 22)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    _msgCtrl.clear();
    _focusNode.unfocus();

    final userMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text.trim(),
        isUser: true,
        timestamp: DateTime.now());

    final loadingMsg = ChatMessage(
        id: 'loading',
        content: '...',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true);

    setState(() {
      _messages.add(userMsg);
      _messages.add(loadingMsg);
      _isSending = true;
    });
    _scrollToBottom();

    final user = context.read<AppState>().currentUser;
    final history = _messages
        .where((m) => !m.isLoading)
        .map((m) => '${m.isUser ? "User" : "AI"}: ${m.content}')
        .toList();

    try {
      final response = await AIService.chatWithAssistant(
        userMessage: text.trim(),
        patientName: user?.name ?? 'Patient',
        conditions: user?.conditions ?? [],
        conversationHistory: history,
      );
      if (mounted) {
        setState(() {
          _aiRouteNote = AIService.lastRouteNote;
          _messages.removeWhere((m) => m.isLoading);
          _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: response,
              isUser: false,
              timestamp: DateTime.now()));
          _isSending = false;
        });
        _scrollToBottom();
        // Speak the response
        _speakResponse(response);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = _formatErrorMessage(e.toString());
        setState(() {
          _aiRouteNote = 'AI request failed';
          _messages.removeWhere((m) => m.isLoading);
          _messages.add(ChatMessage(
              id: 'err',
              content: errorMsg,
              isUser: false,
              timestamp: DateTime.now()));
          _isSending = false;
        });
      }
    }
  }

  /// Speak the AI response using text-to-speech
  Future<void> _speakResponse(String text) async {
    try {
      // Extract just the message part (remove technical sections)
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty).take(5).join(' ');
      await _tts.speak(lines);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  String _formatErrorMessage(String error) {
    if (error.contains('RATE_LIMITED') || error.contains('Too many')) {
      return 'The AI is busy right now. Please wait a moment and try again. (Retrying...) 🔄';
    } else if (error.contains('No internet')) {
      return 'No internet connection. Please check your connection and try again. 📡';
    } else if (error.contains('timed out')) {
      return 'Request took too long. Please try again. ⏱️';
    } else if (error.contains('unavailable')) {
      return 'AI service is temporarily unavailable. Please try again shortly. 🔧';
    } else {
      return 'I am having trouble connecting. Please try again in a moment. 😊';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _providerLabel() {
    switch (AIService.lastProvider) {
      case 'tunnel':
        return 'Local AI';
      case 'cloud':
        return 'Fallback';
      default:
        return 'Idle';
    }
  }

  Color _providerColor() {
    switch (AIService.lastProvider) {
      case 'tunnel':
        return const Color(0xFF2ECC71);
      case 'cloud':
        return AppTheme.warning;
      default:
        return Colors.white70;
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: Color(0xFF9B59B6), shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
                border: Border.all(color: AppTheme.divider)),
            child: const Text('AI is thinking...',
                style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 14,
                    fontStyle: FontStyle.italic)),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 600.ms),
        ]),
      );
    }

    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: Color(0xFF9B59B6), shape: BoxShape.circle),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 20)),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20)),
                border: isUser ? null : Border.all(color: AppTheme.divider),
              ),
              child: Text(message.content,
                  style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isUser ? Colors.white : AppTheme.textPrimary)),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
