import 'package:flutter/foundation.dart';

/// Accessibility Service for screen readers and voice navigation
/// Provides semantic labels and descriptions for all UI elements
class AccessibilityService {
  static const String voiceButtonLabel = 'Voice command button. Tap to start listening.';
  static const String homeTabLabel = 'Home tab. Shows your health dashboard.';
  static const String recordsTabLabel = 'Records tab. Manage your medical documents.';
  static const String medicinesTabLabel = 'Medicines tab. View and manage your medicines.';
  static const String chatTabLabel = 'AI Chat tab. Talk to health assistant.';
  static const String profileTabLabel = 'Profile tab. Manage your account settings.';

  static String medicineItemLabel(String name, String dosage) =>
      '$name, $dosage. Double tap to view details.';

  static String appointmentItemLabel(String doctor, String date, String time) =>
      'Appointment with $doctor on $date at $time. Double tap for details.';

  static String documentItemLabel(String type, String date) =>
      '$type document from $date. Double tap to view.';

  static const String emergencyButtonLabel =
      'Emergency button. Tap to alert emergency contacts.';

  static const String listeningIndicatorLabel =
      'Voice listening indicator. Your device is listening for commands.';

  static const String confirmButtonLabel = 'Confirm button. Tap to confirm your voice command.';

  static const String cancelButtonLabel = 'Cancel button. Tap to cancel voice command.';

  static String navigationButtonLabel(String screen) =>
      'Navigate to $screen. Double tap to go to $screen.';

  static String formFieldLabel(String fieldName) =>
      '$fieldName input field. Double tap to edit.';

  static String switchLabel(String name, bool isEnabled) =>
      '$name. Currently ${isEnabled ? "enabled" : "disabled"}. Double tap to toggle.';

  static String sliderLabel(String name, int value) =>
      '$name slider. Current value: $value. Use arrow keys to adjust.';

  static String listItemLabel(String title, int index, int total) =>
      '$title. Item $index of $total. Double tap for details.';

  static String buttonLabel(String text) => '$text button. Double tap to activate.';

  static const String backButtonLabel = 'Back button. Tap to go back to previous screen.';

  static String searchFieldLabel(String hint) =>
      'Search field. Hint: $hint. Type to search.';

  // Voice command suggestions for screen reader
  static const List<String> voiceCommandExamples = [
    'Show medicines',
    'Show appointments',
    'View documents',
    'Chat with assistant',
    'Go to profile',
    'Emergency alert',
    'दवाई दिखाओ',
    'नियुक्तियां देखें',
    'दस्तावेज़ देखें',
  ];

  static String voiceCommandHelp() => '''
Voice commands you can use:
${voiceCommandExamples.map((cmd) => '- $cmd').join('\n')}

Speak clearly when using voice commands.
''';
}

/// Semantic builder helper for accessible widgets
class a11y {
  /// Create accessible button
  static String button(String label) => AccessibilityService.buttonLabel(label);

  /// Create accessible form field
  static String field(String name) => AccessibilityService.formFieldLabel(name);

  /// Create accessible list item
  static String listItem(String title, int index, int total) =>
      AccessibilityService.listItemLabel(title, index, total);

  /// Create accessible navigation
  static String nav(String screen) => AccessibilityService.navigationButtonLabel(screen);

  /// Get voice command suggestions
  static String voiceHelp() => AccessibilityService.voiceCommandHelp();
}
