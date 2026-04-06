/// Voice Intent Phrases - English & Hindi
/// Bilingual command patterns for elderly users
/// Language-specific synonyms and phrases for better recognition

class VoiceIntentPhrases {
  // ─── Navigation Commands ───────────────────────────────────────────────────

  static const navigationPhrases = {
    'en': {
      'medicines': [
        'show medicines',
        'open medicines',
        'my medicines',
        'medications',
        'pills'
      ],
      'appointments': [
        'show appointments',
        'my appointments',
        'doctor appointments',
        'clinics'
      ],
      'documents': [
        'show documents',
        'my documents',
        'medical records',
        'test reports'
      ],
      'chat': ['open chat', 'talk to ai', 'ai assistant', 'ask doctor'],
      'emergency': ['emergency', 'help me', 'urgent', 'call help'],
      'guardian': ['guardian', 'caregiver', 'show guardian', 'guardian status'],
      'profile': ['my profile', 'my account', 'settings', 'profile info'],
    },
    'hi': {
      'medicines': ['दवाई दिखाओ', 'मेरी दवाई', 'दवाइयों की सूची', 'गोलियां'],
      'appointments': [
        'अपॉइंटमेंट दिखाओ',
        'मेरे अपॉइंटमेंट',
        'डॉक्टर की मुलाकात',
        'क्लिनिक'
      ],
      'documents': [
        'दस्तावेज दिखाओ',
        'मेरे दस्तावेज',
        'चिकित्सा रिकॉर्ड',
        'टेस्ट रिपोर्ट'
      ],
      'chat': ['चैट खोलो', 'ए आई से बात करो', 'सहायक', 'डॉक्टर से पूछो'],
      'emergency': ['आपातकाल', 'मदद करो', 'तुरंत', 'मुझे बुलाओ'],
      'guardian': ['संरक्षक', 'देखभालकर्ता', 'संरक्षक स्थिति'],
      'profile': ['मेरी प्रोफाइल', 'मेरा खाता', 'सेटिंग्स'],
    },
  };

  // ─── Medicine Commands ────────────────────────────────────────────────────

  static const medicinePhrases = {
    'en': {
      'list': [
        'show medicines',
        'list medicines',
        'my medicines',
        'all medicines'
      ],
      'next_dose': [
        'next dose',
        'when is next medicine',
        'upcoming dose',
        'next medicine time'
      ],
      'mark_taken': [
        'mark medicine taken',
        'i took medicine',
        'medicine taken',
        'already took dose'
      ],
      'add_reminder': [
        'add reminder',
        'set alert',
        'notify me',
        'remind me about medicine'
      ],
    },
    'hi': {
      'list': ['दवाई दिखाओ', 'दवाइयों की सूची', 'सभी दवाइयां', 'मेरी दवाइयां'],
      'next_dose': [
        'अगली खुराक',
        'अगली दवाई कब',
        'आने वाली खुराक',
        'अगली बार कब दवाई लेनी है'
      ],
      'mark_taken': ['दवाई ली', 'दवाई ले ली', 'खुराक ली', 'मैंने दवाई ले ली'],
      'add_reminder': [
        'रिमाइंडर सेट करो',
        'नोटिफिकेशन चालू करो',
        'मुझे याद दिलाओ',
        'अलर्ट सेट करो'
      ],
    },
  };

  // ─── Appointment Commands ─────────────────────────────────────────────────

  static const appointmentPhrases = {
    'en': {
      'list': [
        'show appointments',
        'my appointments',
        'upcoming appointments',
        'next appointment'
      ],
      'add': [
        'add appointment',
        'book appointment',
        'schedule appointment',
        'new appointment'
      ],
      'cancel': [
        'cancel appointment',
        'delete appointment',
        'remove appointment'
      ],
    },
    'hi': {
      'list': [
        'अपॉइंटमेंट दिखाओ',
        'मेरे अपॉइंटमेंट',
        'आने वाले अपॉइंटमेंट',
        'अगला अपॉइंटमेंट'
      ],
      'add': [
        'अपॉइंटमेंट जोड़ो',
        'अपॉइंटमेंट बुक करो',
        'अपॉइंटमेंट शेड्यूल करो'
      ],
      'cancel': [
        'अपॉइंटमेंट रद्द करो',
        'अपॉइंटमेंट डिलीट करो',
        'अपॉइंटमेंट हटाओ'
      ],
    },
  };

  // ─── Document Commands ───────────────────────────────────────────────────

  static const documentPhrases = {
    'en': {
      'list': [
        'show documents',
        'my documents',
        'recent documents',
        'latest documents'
      ],
      'open': ['open document', 'show document', 'open recent document'],
    },
    'hi': {
      'list': [
        'दस्तावेज दिखाओ',
        'मेरे दस्तावेज',
        'हाल के दस्तावेज',
        'नवीनतम दस्तावेज'
      ],
      'open': ['दस्तावेज खोलो', 'दस्तावेज दिखाओ'],
    },
  };

  // ─── Emergency Commands ──────────────────────────────────────────────────

  static const emergencyPhrases = {
    'en': {
      'trigger': [
        'emergency',
        'help',
        'sos',
        'urgent',
        'call for help',
        'i need help',
        'mayday'
      ],
    },
    'hi': {
      'trigger': [
        'आपातकाल',
        'मदद',
        'तुरंत',
        'मुझे मदद चाहिए',
        'मुझे बुलाओ',
        'मदद के लिए कॉल',
      ],
    },
  };

  // ─── Guardian Commands ───────────────────────────────────────────────────

  static const guardianPhrases = {
    'en': {
      'status': [
        'show guardian',
        'guardian status',
        'where is guardian',
        'guardian info'
      ],
      'contact': ['contact guardian', 'call guardian', 'message guardian'],
    },
    'hi': {
      'status': [
        'संरक्षक दिखाओ',
        'संरक्षक स्थिति',
        'संरक्षक कहाँ है',
        'संरक्षक की जानकारी'
      ],
      'contact': [
        'संरक्षक को संपर्क करो',
        'संरक्षक को कॉल करो',
        'संरक्षक को संदेश भेजो'
      ],
    },
  };

  // ─── Confirmation Commands ───────────────────────────────────────────────

  static const confirmationPhrases = {
    'en': {
      'yes': ['yes', 'yeah', 'yes please', 'ok', 'okay', 'confirm', 'go ahead'],
      'no': ['no', 'nope', 'cancel', 'stop', 'don\'t', 'negative'],
    },
    'hi': {
      'yes': ['हाँ', 'जी', 'ठीक है', 'हाँ कृपया', 'आगे बढ़ो', 'पुष्टि करो'],
      'no': ['नहीं', 'रद्द करो', 'रुको', 'मत करो', 'नकारात्मक'],
    },
  };

  // ─── Utility Methods ────────────────────────────────────────────────────

  /// Get all command phrases for a specific language
  static Map<String, List<String>?> getPhrasesForLanguage(String language) {
    final lang = language == 'hi' ? 'hi' : 'en';

    return {
      'navigation': navigationPhrases[lang],
      'medicine': medicinePhrases[lang],
      'appointment': appointmentPhrases[lang],
      'document': documentPhrases[lang],
      'emergency': emergencyPhrases[lang],
      'guardian': guardianPhrases[lang],
      'confirmation': confirmationPhrases[lang],
    };
  }

  /// Check if transcript matches a command pattern
  static bool matchesPhrase(String transcript, List<String> phrases) {
    final lower = transcript.toLowerCase().trim();
    return phrases.any((phrase) => lower.contains(phrase.toLowerCase()));
  }

  /// Get language name for display
  static String getLanguageName(String code) {
    return code == 'hi' ? 'Hindi' : 'English';
  }

  /// Get language code from name
  static String getLanguageCode(String name) {
    return name.toLowerCase().contains('hindi') ? 'hi' : 'en';
  }

  /// Get TTS language string
  static String getTTSLanguage(String code) {
    return code == 'hi' ? 'hi-IN' : 'en-US';
  }

  /// Get STT language string
  static String getSTTLanguage(String code) {
    return code == 'hi' ? 'hi_IN' : 'en_US';
  }

  // ─── Age-Appropriate UI Strings ────────────────────────────────────────

  static const uiStrings = {
    'en': {
      'listening': 'Listening...',
      'processing': 'Processing your command...',
      'did_you_say': 'Did you say: ',
      'not_understood': 'Sorry, I didn\'t understand. Please try again.',
      'confirmation_required': 'Please confirm: ',
      'action_confirmed': 'Action confirmed.',
      'action_cancelled': 'Action cancelled.',
      'error_occurred': 'An error occurred. Please try again.',
      'no_permission': 'Microphone permission required.',
      'speak_now': 'Speak now. Say your command.',
    },
    'hi': {
      'listening': 'सुन रहा हूँ...',
      'processing': 'आपकी कमान्ड को प्रोसेस कर रहा हूँ...',
      'did_you_say': 'क्या आपने कहा: ',
      'not_understood':
          'क्षमा करें, मुझे समझ नहीं आया। कृपया फिर से कोशिश करें।',
      'confirmation_required': 'कृपया पुष्टि करें: ',
      'action_confirmed': 'क्रिया पुष्टि हुई।',
      'action_cancelled': 'क्रिया रद्द कर दी गई।',
      'error_occurred': 'एक त्रुटि हुई। कृपया फिर से कोशिश करें।',
      'no_permission': 'माइक्रोफोन की अनुमति आवश्यक है।',
      'speak_now': 'अब बोलिए। अपनी कमान्ड कहें।',
    },
  };

  /// Get UI string for current language
  static String getUIString(String key, String language) {
    final lang = language == 'hi' ? 'hi' : 'en';
    return uiStrings[lang]?[key] ?? key;
  }
}

/// Helper for elderly-friendly voice responses
class VoiceResponseHelper {
  /// Phrase for asking user to repeat (elderly-friendly)
  static String getRepeatPrompt(String language) {
    return VoiceIntentPhrases.getUIString('not_understood', language);
  }

  /// Confirmation prompt with clear TTS (larger pauses, slower speech)
  static String getConfirmationWithSpacing(String text) {
    return '$text. Please say yes to confirm or no to cancel.';
  }

  /// Format a list for TTS (easier for elderly to follow)
  static String formatListForTTS(List<String> items) {
    if (items.isEmpty) return 'No items found.';
    if (items.length == 1) return items.first;

    final buffer = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      buffer.write(items[i]);
      if (i < items.length - 2) {
        buffer.write(', ');
      } else if (i == items.length - 2) {
        buffer.write(', and ');
      }
    }
    return buffer.toString();
  }
}
