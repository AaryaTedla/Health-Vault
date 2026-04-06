import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class AIService {
  static const String _fallbackDayKey = 'ai_cloud_fallback_day';
  static const String _fallbackCountKey = 'ai_cloud_fallback_count';

  static String _lastProvider = 'none';
  static String _lastRouteNote = 'Not started';
  static String get lastProvider => _lastProvider;
  static String get lastRouteNote => _lastRouteNote;

  static Future<String> generateDocumentSummary({
    required String documentText,
    required String documentType,
    required String language,
    required String patientName,
  }) async {
    final langInstruction = language == 'English'
        ? 'Respond only in simple English.'
        : 'Respond only in $language language with very simple words an elderly person can understand.';
    final prompt = """
You are a kind medical assistant helping elderly patients understand their health documents.
Patient Name: $patientName
Document Type: $documentType
Document Content: $documentText
$langInstruction
Write a clear simple explanation with these sections:
What this report shows:
What the numbers mean:
What you should do:
End with: "${AppConstants.medicalDisclaimer}"
Keep total under 250 words.
""";
    return _callAI(prompt);
  }

  static Future<String> chatWithAssistant({
    required String userMessage,
    required String patientName,
    required List<String> conditions,
    required List<String> conversationHistory,
  }) async {
    final condText =
        conditions.isEmpty ? 'None mentioned' : conditions.join(', ');
    final historyText = conversationHistory.length > 6
        ? conversationHistory.sublist(conversationHistory.length - 6).join('\n')
        : conversationHistory.join('\n');
    final prompt = """
You are HealthVault, a warm caring health companion for elderly patients in India.
Patient Name: $patientName
Known Health Conditions: $condText
Recent conversation:
$historyText
Patient message: "$userMessage"
Reply like a caring family member. Simple warm language. Under 150 words.
End with: "${AppConstants.chatDisclaimer}"
""";
    return _callAI(prompt);
  }

  static Future<String> explainSymptom({
    required String symptom,
    required int patientAge,
    required List<String> conditions,
  }) async {
    final prompt = """
A $patientAge-year-old patient says: "$symptom"
Explain simply: causes, warning signs, urgency, one home tip.
Under 120 words.
End with: "${AppConstants.chatDisclaimer}"
""";
    return _callAI(prompt);
  }

  static Future<String> getMedicineInfo(String medicineName) async {
    final prompt = """
Explain "$medicineName" to an elderly patient simply:
What it does, 2 side effects, 1 tip. Under 100 words.
End with: "${AppConstants.chatDisclaimer}"
""";
    return _callAI(prompt);
  }

  /// Understand natural language voice command using AI
  /// Returns JSON with intent and action (e.g., { "intent": "navigate", "action": "medicines", "understood": true })
  static Future<Map<String, dynamic>> understandVoiceCommand({
    required String transcript,
    required String language,
  }) async {
    final langContext = language == 'hi'
        ? 'The user may speak Hindi or English. Respond in English JSON.'
        : 'Respond in English JSON.';

    final prompt = """
Parse this voice command: "$transcript"
$langContext

Return ONLY valid JSON (no markdown, no text before/after):
{
  "understood": true/false,
  "intent": "navigate|medicine|appointment|document|emergency|chat|profile|unknown",
  "action": "medicines|appointments|documents|chat|profile|home|emergency",
  "confidence": 0.0-1.0,
  "clarification": "If not understood, suggest what user might want"
}

Examples:
- "show my medicines" → {"understood": true, "intent": "navigate", "action": "medicines", "confidence": 0.95}
- "दवाई दिखाओ" → {"understood": true, "intent": "navigate", "action": "medicines", "confidence": 0.95}
- "help" → {"understood": false, "intent": "unknown", "action": "", "confidence": 0.3, "clarification": "I can help you view medicines, appointments, documents, or chat with me. What would you like?"}
- "blah blah blah" → {"understood": false, "intent": "unknown", "action": "", "confidence": 0.1, "clarification": "I didn't understand that. Could you ask me about medicines, appointments, or documents?"}
""";

    try {
      final response = await _callAI(prompt);

      // Try to parse as JSON - handle various edge cases
      String jsonStr = response.trim();

      // Remove markdown code blocks if present
      if (jsonStr.startsWith('```')) {
        jsonStr =
            jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return {
        'understood': data['understood'] ?? false,
        'intent': data['intent'] ?? 'unknown',
        'action': data['action'] ?? '',
        'confidence': (data['confidence'] ?? 0.0).toDouble(),
        'clarification': data['clarification'] ??
            'I didn\'t understand that. Could you try again?',
      };
    } catch (e) {
      debugPrint('Voice intent parsing error: $e');
      return {
        'understood': false,
        'intent': 'unknown',
        'action': '',
        'confidence': 0.0,
        'clarification':
            'Sorry, I had trouble understanding. Please try again.',
      };
    }
  }

  static Future<String> _callAI(String prompt) async {
    _lastProvider = 'none';
    _lastRouteNote = 'Routing request...';

    final tunnelBaseUrl = AppConstants.tunnelBaseUrl.trim();
    final tunnelToken = AppConstants.tunnelAuthToken.trim();
    if (tunnelBaseUrl.isNotEmpty) {
      try {
        final text = await _callTunnelProvider(
          baseUrl: tunnelBaseUrl,
          authToken: tunnelToken,
          prompt: prompt,
        ).timeout(const Duration(seconds: 25));
        _lastProvider = 'tunnel';
        _lastRouteNote = 'Connected to local AI tunnel';
        return text;
      } on SocketException {
        _lastRouteNote =
            'Tunnel unavailable due to network error. Trying cloud fallback.';
      } on TimeoutException {
        _lastRouteNote = 'Tunnel timed out. Trying cloud fallback.';
      } catch (e) {
        _lastRouteNote = 'Tunnel failed ($e). Trying cloud fallback.';
      }
    } else {
      _lastRouteNote = 'Tunnel not configured. Trying cloud fallback.';
    }

    final apiKey = AppConstants.geminiApiKey.trim();
    if (apiKey.isEmpty) {
      return 'Local AI tunnel is unavailable and cloud fallback is not configured.';
    }

    if (!await _canUseCloudFallback()) {
      return 'Cloud fallback limit reached for today. Please restore tunnel connectivity.';
    }

    try {
      final response = await _callCloudProvider(apiKey: apiKey, prompt: prompt)
          .timeout(const Duration(seconds: 30));
      await _incrementCloudFallbackCount();
      _lastProvider = 'cloud';
      _lastRouteNote = 'Running in cloud fallback mode';
      return response;
    } on SocketException {
      return 'No internet connection.';
    } on TimeoutException {
      return 'Request timed out. Please try again.';
    } catch (e) {
      print('Error: $e');
      return 'Error: $e';
    }
  }

  static Future<String> _callTunnelProvider({
    required String baseUrl,
    required String authToken,
    required String prompt,
  }) async {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.post(
      Uri.parse('$normalizedBaseUrl/v1/chat/completions'),
      headers: headers,
      body: jsonEncode({
        'model': AppConstants.tunnelModel,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 500,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Tunnel API error ${response.statusCode}: ${_safeBody(response.body)}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractResponseText(data);
    if (text.isEmpty) {
      throw Exception('Tunnel response was empty.');
    }
    return text;
  }

  static Future<String> _callCloudProvider({
    required String apiKey,
    required String prompt,
  }) async {
    // Use Google Gemini 2.0 Flash API (latest, faster model)
    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 500,
          'temperature': 0.7,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      try {
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String? ?? '';
            if (text.isNotEmpty) return text;
          }
        }
      } catch (e) {
        debugPrint('Error parsing Gemini response: $e');
      }
      throw Exception('Gemini response was empty or malformed.');
    }

    if (response.statusCode == 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final error = data['error']?['message'] ?? 'Bad request';
      throw Exception('API error: $error');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
          'Invalid API key. Please check your Gemini API key in settings.');
    }
    if (response.statusCode == 429) {
      throw Exception('Too many requests. Please wait and try again.');
    }

    throw Exception(
        'API error ${response.statusCode}: ${_safeBody(response.body)}');
  }

  static String _extractResponseText(Map<String, dynamic> data) {
    final fromChoices =
        data['choices'] is List && (data['choices'] as List).isNotEmpty
            ? (data['choices'] as List).first
            : null;

    if (fromChoices is Map<String, dynamic>) {
      final message = fromChoices['message'];
      if (message is Map<String, dynamic>) {
        final content = message['content'];
        if (content is String && content.trim().isNotEmpty) {
          return content.trim();
        }
      }

      final text = fromChoices['text'];
      if (text is String && text.trim().isNotEmpty) {
        return text.trim();
      }
    }

    final response = data['response'];
    if (response is String && response.trim().isNotEmpty) {
      return response.trim();
    }

    final text = data['text'];
    if (text is String && text.trim().isNotEmpty) {
      return text.trim();
    }

    return '';
  }

  static String _safeBody(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length <= 200) return trimmed;
    return '${trimmed.substring(0, 200)}...';
  }

  static String _todayToken() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static Future<bool> _canUseCloudFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayToken();
    final storedDay = prefs.getString(_fallbackDayKey);

    if (storedDay != today) {
      await prefs.setString(_fallbackDayKey, today);
      await prefs.setInt(_fallbackCountKey, 0);
      return true;
    }

    final currentCount = prefs.getInt(_fallbackCountKey) ?? 0;
    return currentCount < AppConstants.cloudFallbackDailyCap;
  }

  static Future<void> _incrementCloudFallbackCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayToken();
    final storedDay = prefs.getString(_fallbackDayKey);

    if (storedDay != today) {
      await prefs.setString(_fallbackDayKey, today);
      await prefs.setInt(_fallbackCountKey, 1);
      return;
    }

    final currentCount = prefs.getInt(_fallbackCountKey) ?? 0;
    await prefs.setInt(_fallbackCountKey, currentCount + 1);
  }
}
