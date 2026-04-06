import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Complete localization service for HealthVault
/// Supports dynamic language switching with persisted preferences
class LocalizationService {
  static const String _languagePrefsKey = 'app_language';
  static final LocalizationService _instance = LocalizationService._internal();

  String _currentLanguage = 'en'; // 'en' or 'hi'
  late Map<String, Map<String, String>> _translations;

  factory LocalizationService() {
    return _instance;
  }

  LocalizationService._internal() {
    _initializeTranslations();
  }

  String get currentLanguage => _currentLanguage;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languagePrefsKey) ?? 'en';
  }

  Future<void> setLanguage(String language) async {
    if (language != 'en' && language != 'hi') return;
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePrefsKey, language);
  }

  String t(String key) {
    return _translations[_currentLanguage]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  void _initializeTranslations() {
    _translations = {
      'en': {
        // App
        'app_name': 'HealthVault',
        'home': 'Home',
        'records': 'Records',
        'medicines': 'Medicines',
        'ai_chat': 'AI Chat',
        'profile': 'Profile',
        'settings': 'Settings',
        'logout': 'Logout',

        // Auth
        'sign_in': 'Sign In',
        'sign_up': 'Sign Up',
        'email': 'Email',
        'password': 'Password',
        'phone': 'Phone Number',
        'name': 'Full Name',
        'age': 'Age',
        'blood_group': 'Blood Group',
        'account_type': 'Account Type',
        'patient': 'Patient',
        'guardian': 'Guardian',
        'conditions': 'Health Conditions',
        'emergency_contacts': 'Emergency Contacts',

        // Medicines
        'add_medicine': 'Add Medicine',
        'medicine_name': 'Medicine Name',
        'dosage': 'Dosage',
        'frequency': 'Frequency',
        'next_dose': 'Next Dose',
        'mark_taken': 'Mark as Taken',
        'medicine_reminder': 'Medicine Reminder',
        'medicine_schedule': 'Medicine Schedule',

        // Appointments
        'appointments': 'Appointments',
        'add_appointment': 'Add Appointment',
        'doctor_name': 'Doctor Name',
        'clinic': 'Clinic/Hospital',
        'appointment_date': 'Date',
        'appointment_time': 'Time',
        'upcoming_appointments': 'Upcoming Appointments',
        'past_appointments': 'Past Appointments',

        // Documents
        'documents': 'Medical Documents',
        'upload_document': 'Upload Document',
        'document_type': 'Document Type',
        'prescription': 'Prescription',
        'lab_report': 'Lab Report',
        'x_ray': 'Scan / X-Ray',
        'discharge_summary': 'Discharge Summary',
        'medical_bill': 'Medical Bill',

        // Voice
        'listening': 'Listening...',
        'processing_speech': 'Processing speech...',
        'confirm': 'Confirm',
        'cancel': 'Cancel',
        'voice_command': 'Voice Command',
        'microphone': 'Microphone',
        'mic_permission_denied':
            'Microphone permission denied. Please enable in settings.',
        'voice_not_available': 'Voice not available on this device',

        // Chat
        'chat': 'Chat',
        'message': 'Message',
        'send': 'Send',
        'type_message': 'Type your message...',
        'ai_assistant': 'AI Health Assistant',

        // Guardian
        'guardian': 'Guardian',
        'linked_patient': 'Linked Patient',
        'link_patient': 'Link Patient',
        'emergency_response': 'Emergency Response',
        'caregiver': 'Caregiver',

        // Emergency
        'emergency': 'Emergency',
        'emergency_alert': 'Emergency Alert',
        'call_emergency': 'Call Emergency Services',
        'notify_contacts': 'Notify Emergency Contacts',

        // Common
        'save': 'Save',
        'edit': 'Edit',
        'delete': 'Delete',
        'back': 'Back',
        'next': 'Next',
        'skip': 'Skip',
        'done': 'Done',
        'loading': 'Loading...',
        'error': 'Error',
        'success': 'Success',
        'close': 'Close',
        'ok': 'OK',
        'yes': 'Yes',
        'no': 'No',
        'search': 'Search',
        'filter': 'Filter',
        'sort': 'Sort',
        'menu': 'Menu',

        // Accessibility
        'tab_navigation': 'Navigation',
        'button': 'Button',
        'text_input': 'Text input',
        'close_dialog': 'Close dialog',
        'expand': 'Expand',
        'collapse': 'Collapse',
      },
      'hi': {
        // App
        'app_name': 'HealthVault',
        'home': 'होम',
        'records': 'दस्तावेज़',
        'medicines': 'दवाइयां',
        'ai_chat': 'एआई चैट',
        'profile': 'प्रोफ़ाइल',
        'settings': 'सेटिंग्स',
        'logout': 'लॉगआउट',

        // Auth
        'sign_in': 'लॉगिन करें',
        'sign_up': 'रजिस्टर करें',
        'email': 'ईमेल',
        'password': 'पासवर्ड',
        'phone': 'फोन नंबर',
        'name': 'पूरा नाम',
        'age': 'उम्र',
        'blood_group': 'रक्त प्रकार',
        'account_type': 'खाता प्रकार',
        'patient': 'रोगी',
        'guardian': 'देखभालकर्ता',
        'conditions': 'स्वास्थ्य स्थितियां',
        'emergency_contacts': 'आपातकालीन संपर्क',

        // Medicines
        'add_medicine': 'दवा जोड़ें',
        'medicine_name': 'दवा का नाम',
        'dosage': 'खुराक',
        'frequency': 'आवृत्ति',
        'next_dose': 'अगली खुराक',
        'mark_taken': 'लिया गया चिह्नित करें',
        'medicine_reminder': 'दवा की याद दिलाई',
        'medicine_schedule': 'दवा का समय',

        // Appointments
        'appointments': 'अपॉइंटमेंट',
        'add_appointment': 'अपॉइंटमेंट जोड़ें',
        'doctor_name': 'डॉक्टर का नाम',
        'clinic': 'क्लिनिक/अस्पताल',
        'appointment_date': 'तारीख',
        'appointment_time': 'समय',
        'upcoming_appointments': 'आने वाली अपॉइंटमेंट',
        'past_appointments': 'पिछली अपॉइंटमेंट',

        // Documents
        'documents': 'चिकित्सा दस्तावेज़',
        'upload_document': 'दस्तावेज़ अपलोड करें',
        'document_type': 'दस्तावेज़ प्रकार',
        'prescription': 'प्रिस्क्रिप्शन',
        'lab_report': 'लैब रिपोर्ट',
        'x_ray': 'स्कैन / एक्स-रे',
        'discharge_summary': 'डिस्चार्ज सारांश',
        'medical_bill': 'चिकित्सा बिल',

        // Voice
        'listening': 'सुन रहे हैं...',
        'processing_speech': 'भाषण संसाधित कर रहे हैं...',
        'confirm': 'पुष्टि करें',
        'cancel': 'रद्द करें',
        'voice_command': 'वॉइस कमांड',
        'microphone': 'माइक्रोफोन',
        'mic_permission_denied':
            'माइक्रोफोन अनुमति अस्वीकृत। कृपया सेटिंग्स में सक्षम करें।',
        'voice_not_available': 'इस डिवाइस पर वॉइस उपलब्ध नहीं',

        // Chat
        'chat': 'चैट',
        'message': 'संदेश',
        'send': 'भेजें',
        'type_message': 'अपना संदेश टाइप करें...',
        'ai_assistant': 'एआई स्वास्थ्य सहायक',

        // Guardian
        'guardian': 'देखभालकर्ता',
        'linked_patient': 'जुड़ा हुआ रोगी',
        'link_patient': 'रोगी को जोड़ें',
        'emergency_response': 'आपातकालीन प्रतिक्रिया',
        'caregiver': 'देखभालकर्ता',

        // Emergency
        'emergency': 'आपातकाल',
        'emergency_alert': 'आपातकालीन सतर्कता',
        'call_emergency': 'आपातकालीन सेवाओं को कॉल करें',
        'notify_contacts': 'आपातकालीन संपर्कों को सूचित करें',

        // Common
        'save': 'सहेजें',
        'edit': 'संपादित करें',
        'delete': 'हटाएं',
        'back': 'वापस',
        'next': 'अगला',
        'skip': 'छोड़ें',
        'done': 'हो गया',
        'loading': 'लोड हो रहा है...',
        'error': 'त्रुटि',
        'success': 'सफल',
        'close': 'बंद करें',
        'ok': 'ठीक है',
        'yes': 'हाँ',
        'no': 'नहीं',
        'search': 'खोजें',
        'filter': 'फ़िल्टर करें',
        'sort': 'क्रमबद्ध करें',
        'menu': 'मेनू',

        // Accessibility
        'tab_navigation': 'नेविगेशन',
        'button': 'बटन',
        'text_input': 'पाठ इनपुट',
        'close_dialog': 'डायलॉग बंद करें',
        'expand': 'विस्तारित करें',
        'collapse': 'संक्षिप्त करें',
      }
    };
  }
}

final localization = LocalizationService();
