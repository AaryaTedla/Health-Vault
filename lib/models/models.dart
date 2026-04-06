// ─── User Model ───────────────────────────────────────────────────────────────
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String accountType; // 'patient' | 'guardian'
  final String language;
  final String? linkedPatientId;
  final List<String> guardianIds;
  final List<EmergencyContact> emergencyContacts;
  final DateTime createdAt;
  final int? age;
  final String? bloodGroup;
  final List<String> conditions;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.accountType,
    this.language = 'English',
    this.linkedPatientId,
    this.guardianIds = const [],
    this.emergencyContacts = const [],
    required this.createdAt,
    this.age,
    this.bloodGroup,
    this.conditions = const [],
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      accountType: map['accountType'] ?? 'patient',
      language: map['language'] ?? 'English',
      linkedPatientId: map['linkedPatientId'],
      guardianIds: List<String>.from(map['guardianIds'] ?? []),
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>? ?? [])
          .map((e) => EmergencyContact.fromMap(e))
          .toList(),
      createdAt: _dateTimeFromDynamic(map['createdAt']) ?? DateTime.now(),
      age: map['age'],
      bloodGroup: map['bloodGroup'],
      conditions: List<String>.from(map['conditions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'accountType': accountType,
        'language': language,
        'linkedPatientId': linkedPatientId,
        'guardianIds': guardianIds,
        'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'age': age,
        'bloodGroup': bloodGroup,
        'conditions': conditions,
      };

  bool get isPatient => accountType == 'patient';
  bool get isGuardian => accountType == 'guardian';
}

// ─── Emergency Contact ────────────────────────────────────────────────────────
class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  EmergencyContact(
      {required this.name, required this.phone, required this.relation});

  factory EmergencyContact.fromMap(Map<String, dynamic> map) =>
      EmergencyContact(
          name: map['name'] ?? '',
          phone: map['phone'] ?? '',
          relation: map['relation'] ?? '');

  Map<String, dynamic> toMap() =>
      {'name': name, 'phone': phone, 'relation': relation};
}

// ─── Health Document ──────────────────────────────────────────────────────────
class HealthDocument {
  final String id;
  final String patientId;
  final String name;
  final String hospitalName;
  final String documentType;
  final String fileUrl;
  final String fileType; // 'pdf' | 'image'
  final String? notes;
  final String? aiSummary;
  final String? aiSummaryHindi;
  final String? aiSummaryTelugu;
  final String? aiSummaryKannada;
  final String? aiSummaryTamil;
  final DateTime uploadedAt;
  final double? fileSize;

  HealthDocument({
    required this.id,
    required this.patientId,
    required this.name,
    required this.hospitalName,
    required this.documentType,
    required this.fileUrl,
    required this.fileType,
    this.notes,
    this.aiSummary,
    this.aiSummaryHindi,
    this.aiSummaryTelugu,
    this.aiSummaryKannada,
    this.aiSummaryTamil,
    required this.uploadedAt,
    this.fileSize,
  });

  factory HealthDocument.fromMap(Map<String, dynamic> map) {
    return HealthDocument(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      name: map['name'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      documentType: map['documentType'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? 'pdf',
      notes: map['notes'],
      aiSummary: map['aiSummary'],
      aiSummaryHindi: map['aiSummaryHindi'],
      aiSummaryTelugu: map['aiSummaryTelugu'],
      aiSummaryKannada: map['aiSummaryKannada'],
      aiSummaryTamil: map['aiSummaryTamil'],
      uploadedAt: _dateTimeFromDynamic(map['uploadedAt']) ?? DateTime.now(),
      fileSize: map['fileSize']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'patientId': patientId,
        'name': name,
        'hospitalName': hospitalName,
        'documentType': documentType,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'notes': notes,
        'aiSummary': aiSummary,
        'aiSummaryHindi': aiSummaryHindi,
        'aiSummaryTelugu': aiSummaryTelugu,
        'aiSummaryKannada': aiSummaryKannada,
        'aiSummaryTamil': aiSummaryTamil,
        'uploadedAt': uploadedAt.toIso8601String(),
        'fileSize': fileSize,
      };

  String? summaryForLanguage(String lang) {
    switch (lang) {
      case 'Hindi':
        return aiSummaryHindi ?? aiSummary;
      case 'Telugu':
        return aiSummaryTelugu ?? aiSummary;
      case 'Kannada':
        return aiSummaryKannada ?? aiSummary;
      case 'Tamil':
        return aiSummaryTamil ?? aiSummary;
      default:
        return aiSummary;
    }
  }
}

// ─── Medicine Reminder ────────────────────────────────────────────────────────
class MedicineReminder {
  final String id;
  final String patientId;
  final String medicineName;
  final String dosage;
  final String frequency;
  final List<String> times; // e.g. ['08:00', '20:00']
  final String duration; // e.g. '30 days'
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? lastTakenAt;
  final String? notes;
  final String? color; // pill color hex

  MedicineReminder({
    required this.id,
    required this.patientId,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.duration,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.lastTakenAt,
    this.notes,
    this.color,
  });

  factory MedicineReminder.fromMap(Map<String, dynamic> map) {
    return MedicineReminder(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      times: List<String>.from(map['times'] ?? []),
      duration: map['duration'] ?? '',
      startDate: _dateTimeFromDynamic(map['startDate']) ?? DateTime.now(),
      endDate: _dateTimeFromDynamic(map['endDate']),
      isActive: map['isActive'] ?? true,
      lastTakenAt: _dateTimeFromDynamic(map['lastTakenAt']),
      notes: map['notes'],
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'patientId': patientId,
        'medicineName': medicineName,
        'dosage': dosage,
        'frequency': frequency,
        'times': times,
        'duration': duration,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'lastTakenAt': lastTakenAt?.toIso8601String(),
        'isActive': isActive,
        'notes': notes,
        'color': color,
      };
}

// ─── Chat Message ─────────────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });
}

// ─── Health Stats ─────────────────────────────────────────────────────────────
class HealthStat {
  final String label;
  final String value;
  final String unit;
  final String icon;
  final int color;
  final String trend;

  HealthStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.trend,
  });
}

class Appointment {
  final String id;
  final String patientId;
  final String title;
  final String hospital;
  final DateTime dateTime;
  final String? notes;
  final bool completed;

  Appointment({
    required this.id,
    required this.patientId,
    required this.title,
    required this.hospital,
    required this.dateTime,
    this.notes,
    this.completed = false,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      title: map['title'] ?? '',
      hospital: map['hospital'] ?? '',
      dateTime: _dateTimeFromDynamic(map['dateTime']) ?? DateTime.now(),
      notes: map['notes'],
      completed: map['completed'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'patientId': patientId,
        'title': title,
        'hospital': hospital,
        'dateTime': dateTime.toIso8601String(),
        'notes': notes,
        'completed': completed,
      };
}

// ─── Voice & Audio Models ─────────────────────────────────────────────────────
enum VoiceState {
  idle, // Ready for input
  listening, // Recording audio
  transcribing, // Converting speech to text
  confirming, // Showing user "Did you say this?"
  executing, // Running the command
  speaking, // TTS output
  error, // Error state
}

enum VoiceIntentType {
  navigate, // Navigate to screen
  medicine, // Medicine operations
  appointment, // Appointment operations
  document, // Document operations
  emergency, // Emergency trigger
  guardian, // Guardian status
  profile, // Profile operations
  help, // Show voice command guide
  unknown, // Unknown intent
}

enum VoiceOutcome {
  success, // Action completed successfully
  cancelled, // User cancelled the action
  failed, // Action failed
  timeout, // Voice operation timed out
  noSpeech, // No speech detected
  micDenied, // Microphone permission denied
  stsFailed, // Speech-to-text failed
  ttsFailed, // Text-to-speech failed
}

class VoiceSession {
  final String id;
  final String language; // 'en', 'hi'
  final VoiceState state;
  final String? transcript; // What user said
  final VoiceIntentType? intent; // Recognized intent
  final double? confidence; // 0.0 to 1.0
  final DateTime startedAt;
  final DateTime? endedAt;
  final VoiceOutcome? outcome;
  final String? errorMessage;
  final Map<String, dynamic>? actionParams; // What to execute

  VoiceSession({
    required this.id,
    required this.language,
    required this.state,
    this.transcript,
    this.intent,
    this.confidence,
    required this.startedAt,
    this.endedAt,
    this.outcome,
    this.errorMessage,
    this.actionParams,
  });

  Duration? get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  bool get isActive => state != VoiceState.idle && endedAt == null;

  factory VoiceSession.fromMap(Map<String, dynamic> map) {
    return VoiceSession(
      id: map['id'] ?? '',
      language: map['language'] ?? 'en',
      state: _voiceStateFromString(map['state']),
      transcript: map['transcript'],
      intent: _voiceIntentTypeFromString(map['intent']),
      confidence: map['confidence'],
      startedAt: _dateTimeFromDynamic(map['startedAt']) ?? DateTime.now(),
      endedAt: _dateTimeFromDynamic(map['endedAt']),
      outcome: _voiceOutcomeFromString(map['outcome']),
      errorMessage: map['errorMessage'],
      actionParams: map['actionParams'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'language': language,
        'state': state.toString(),
        'transcript': transcript,
        'intent': intent.toString(),
        'confidence': confidence,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'outcome': outcome.toString(),
        'errorMessage': errorMessage,
        'actionParams': actionParams,
      };
}

VoiceState _voiceStateFromString(String? value) {
  if (value == null) return VoiceState.idle;
  return VoiceState.values.firstWhere(
    (e) => e.toString() == 'VoiceState.$value',
    orElse: () => VoiceState.idle,
  );
}

VoiceIntentType _voiceIntentTypeFromString(String? value) {
  if (value == null) return VoiceIntentType.unknown;
  return VoiceIntentType.values.firstWhere(
    (e) => e.toString() == 'VoiceIntentType.$value',
    orElse: () => VoiceIntentType.unknown,
  );
}

VoiceOutcome? _voiceOutcomeFromString(String? value) {
  if (value == null) return null;
  try {
    return VoiceOutcome.values.firstWhere(
      (e) => e.toString() == 'VoiceOutcome.$value',
    );
  } catch (_) {
    return null;
  }
}

DateTime? _dateTimeFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
