import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/app_theme.dart';

class AIService {

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
    final condText = conditions.isEmpty ? 'None mentioned' : conditions.join(', ');
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

  static Future<String> _callAI(String prompt) async {
    final apiKey = AppConstants.geminiApiKey;

    if (apiKey.trim().isEmpty) {
      return 'Please add your API key in app_theme.dart';
    }

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://healthvault.app',
          'X-Title': 'HealthVault',
        },
        body: jsonEncode({
          'model': 'google/gemma-3-4b-it:free',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 500,
        }),
      ).timeout(const Duration(seconds: 30));

      print('=== AI DEBUG ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'];
        if (text != null && text.toString().trim().isNotEmpty) {
          print('AI responded successfully!');
          return text.toString().trim();
        }
        return 'Empty response. Please try again.';
      } else if (response.statusCode == 401) {
        return 'Invalid API key. Please check your OpenRouter key.';
      } else if (response.statusCode == 429) {
        return 'Too many requests. Please wait and try again.';
      } else {
        return 'API error ${response.statusCode}: ${response.body}';
      }
    } on SocketException {
      return 'No internet connection.';
    } on TimeoutException {
      return 'Request timed out. Please try again.';
    } catch (e) {
      print('Error: $e');
      return 'Error: $e';
    }
  }
}