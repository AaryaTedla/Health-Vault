# HealthVault

HealthVault is an elderly-first Flutter app for managing health records, medicines, appointments, and emergency workflows, with AI assistance and patient-guardian collaboration.

## What Is Implemented

### Patient Experience
- Email/password authentication with role selection (patient or guardian)
- Terms and medical disclaimer acceptance during onboarding
- Home dashboard with health stats, quick actions, and emergency access
- Records management with upload, search, filter, and delete
- Medical document upload for PDF/JPG/JPEG/PNG files
- OCR extraction from uploaded files (ML Kit + PDF extraction flow)
- AI-generated document summaries with medical disclaimer
- AI health chat with quick prompts and short conversational context
- Medicine reminder CRUD with adherence tracking and missed/overdue indicators
- Medicine autofill suggestions from bundled medicine dataset
- Appointment add/list/complete/delete flow
- Medical history timeline and usage analytics views
- Emergency contacts management from profile
- SOS flow with contact selection, local emergency notifications, and SMS compose intent
- Emergency live-location sharing window with guardian-visible coordinates
- Data export to JSON file

### Guardian Experience
- Guardian dashboard with linked patient status overview
- Patient linking via invite code and pairing request approval flow
- Permission-aware access to linked patient data
- Read access to records and medicines based on patient-granted permissions
- Guardian emergency response logging and live-location visibility when enabled

### Voice and Accessibility
- Voice command pipeline with speech-to-text and text-to-speech
- Voice intents for navigation and common health actions
- Voice command guide UI in app
- Large touch targets, larger typography, and accessibility-friendly theme settings
- Persistent app language support via localization service (English and Hindi UI strings)

### AI and Reliability
- AI routing with tunnel-first strategy and cloud fallback
- Retry logic with exponential backoff for temporary rate-limit failures
- Runtime route/provider status tracking for diagnostics

## Tech Stack

- Flutter + Dart
- Provider for app state
- Firebase Auth + Cloud Firestore
- Local notifications via flutter_local_notifications
- OCR via google_mlkit_text_recognition
- PDF text extraction via syncfusion_flutter_pdf
- Voice via speech_to_text and flutter_tts
- Location via geolocator
- Charts via fl_chart
- Maps via flutter_map + OpenStreetMap tiles

## Project Structure

```text
lib/
  main.dart
  models/models.dart
  screens/
    ai_chat_screen.dart
    ai_summary_screen.dart
    appointment_screen.dart
    auth_screens.dart
    dashboard_screen.dart
    documents_screen.dart
    emergency_screen.dart
    guardian_dashboard_screen.dart
    main_shell.dart
    medical_history_screen.dart
    medicine_screen.dart
    terms_screen.dart
    upload_document_screen.dart
    usage_analytics_screen.dart
  services/
    accessibility_service.dart
    ai_service.dart
    app_state.dart
    audit_service.dart
    document_text_extractor.dart
    firebase_service.dart
    localization_service.dart
    medicine_autofill_service.dart
    native_intent_service.dart
    notification_service.dart
    risk_flag_service.dart
    voice_agent_service.dart
    voice_intent_router.dart
    voice_intents_en_hi.dart
  utils/app_theme.dart
  widgets/shared_widgets.dart

assets/
  data/medicines_v2.json
  images/
  icons/
```

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

Required for auth, cloud sync, pairing, and guardian workflows.

1. Add Android config file:

```text
android/app/google-services.json
```

2. Deploy Firestore rules:

```bash
firebase login
firebase use <project-id>
firebase deploy --only firestore:rules
```

### 3. Configure environment

Copy .env.example to .env and set your key:

```env
OPENROUTER_API_KEY=your_key_here
```

Optional runtime variables supported by the app:
- HEALTHVAULT_TUNNEL_URL
- HEALTHVAULT_TUNNEL_TOKEN
- HEALTHVAULT_TUNNEL_MODEL
- HEALTHVAULT_CLOUD_FALLBACK_DAILY_CAP

You can also pass values with dart-define.

### 4. Run

```bash
flutter run
```

## Build

### Release APK

```bash
flutter build apk --release
```

Output path:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Split per ABI (smaller APKs)

```bash
flutter build apk --release --split-per-abi
```

## Firestore Data Model (High Level)

Main collections and subcollections used by the app include:
- users
- pairingCodes
- pairingRequests
- users/{patientId}/careLinks
- documents
- medicines
- appointments
- auditLogs
- live location status documents for emergency sharing

Role and permission checks are enforced via Firestore rules.

## Known Limitations

- Android-focused implementation; iOS/web flows are not the primary target
- Emergency services call button UI exists, but direct emergency-call execution is not fully wired
- Many features rely on Firebase/network availability
- AI responses are informational only and not a medical diagnosis

## Development Commands

```bash
flutter analyze
flutter test
```

## Disclaimer

HealthVault provides supportive information only. It is not a replacement for professional medical advice, diagnosis, or treatment.
