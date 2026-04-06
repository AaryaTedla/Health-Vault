import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeIntentService {
  static const MethodChannel _channel = MethodChannel('healthvault/native_intent');

  static Future<bool> callPhoneNumber(String phoneNumber) async {
    if (kIsWeb) return false;
    final cleaned = phoneNumber.trim();
    if (cleaned.isEmpty) return false;

    try {
      final result = await _channel.invokeMethod<bool>('callPhoneNumber', {
        'phoneNumber': cleaned,
      });
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> composeSms({
    required List<String> recipients,
    required String message,
  }) async {
    if (kIsWeb) return false;
    final cleanedRecipients = recipients
        .map((phone) => phone.trim())
        .where((phone) => phone.isNotEmpty)
        .toList(growable: false);
    if (cleanedRecipients.isEmpty) return false;

    try {
      final result = await _channel.invokeMethod<bool>('composeSms', {
        'recipients': cleanedRecipients,
        'message': message,
      });
      return result == true;
    } catch (_) {
      return false;
    }
  }
}