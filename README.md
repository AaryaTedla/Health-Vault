# HealthVault

A Flutter application for managing personal health records, medicine reminders, AI-assisted summaries/chat, and patient-guardian collaboration.

## Overview

HealthVault helps users:
- Store and organize medical records
- Track medicines and reminders
- View health history and usage insights
- Use AI features for summaries and chat assistance
- Share access with guardians using permission-based controls

## Tech Stack

- Flutter (Dart)
- Provider (state management)
- Firebase Auth
- Cloud Firestore
- Local notifications

## Project Structure (Detailed)

```text
healthvault_ai/
├── lib/
│   ├── main.dart
│   │   └── App bootstrap: dotenv load, Firebase init, notifications init,
│   │      provider wiring, root MaterialApp
│   ├── models/
│   │   └── models.dart
│   │      └── Data models: AppUser, HealthDocument, MedicineReminder,
│   │         Appointment, ChatMessage, EmergencyContact, etc.
│   ├── services/
│   │   ├── app_state.dart
│   │   │   └── Central state layer (Provider): auth/session, role context,
│   │   │      docs/medicines/appointments CRUD, permissions, export/delete,
│   │   │      reminder scheduling, pairing orchestration
│   │   ├── ai_service.dart
│   │   │   └── AI request handling (summary/chat prompts + responses)
│   │   ├── firebase_service.dart
│   │   │   └── Firebase adapters: auth, profile, Firestore reads/writes,
│   │   │      pairing workflows
│   │   ├── medicine_autofill_service.dart
│   │   │   └── Dataset-backed medicine suggestion engine with indexing,
│   │   │      ranking, typo rescue
│   │   ├── notification_service.dart
│   │   │   └── Local notification channels, medicine schedules, SOS alerts,
│   │   │      missed-dose alerts
│   │   ├── document_text_extractor.dart
│   │   │   └── OCR text extraction and lightweight structured field extraction
│   │   ├── audit_service.dart
│   │   │   └── Writes activity logs to Firestore auditLogs
│   │   └── risk_flag_service.dart
│   │       └── Rule-based medicine risk flag generation
│   ├── screens/
│   │   ├── auth_screens.dart
│   │   │   └── Login + multi-step signup + terms acceptance
│   │   ├── main_shell.dart
│   │   │   └── Bottom navigation shell + role-aware tab routing + profile
│   │   ├── dashboard_screen.dart
│   │   │   └── Patient home: quick actions, stats, notifications sheet
│   │   ├── guardian_dashboard_screen.dart
│   │   │   └── Guardian home: linked patient overview and updates
│   │   ├── documents_screen.dart
│   │   │   └── Records listing, searching, filtering, access gating
│   │   ├── upload_document_screen.dart
│   │   │   └── File pick/upload + OCR + AI summary trigger
│   │   ├── ai_summary_screen.dart
│   │   │   └── AI report summary rendering + disclaimer
│   │   ├── ai_chat_screen.dart
│   │   │   └── Chat UI, quick prompts, disclaimer, keyboard-aware behavior
│   │   ├── medicine_screen.dart
│   │   │   └── Medicine list/add/take/delete + autofill + risk/overdue banners
│   │   ├── medical_history_screen.dart
│   │   │   └── Live dashboard, timeline, insights and planning actions
│   │   ├── appointment_screen.dart
│   │   │   └── Appointment CRUD and completion state
│   │   ├── usage_analytics_screen.dart
│   │   │   └── Usage stats and trend visualizations
│   │   ├── emergency_screen.dart
│   │   │   └── SOS flow with contact selection and emergency notifications
│   │   └── terms_screen.dart
│   │       └── Terms + mandatory medical disclaimer acceptance
│   ├── widgets/
│   │   └── shared_widgets.dart
│   │      └── Reusable UI widgets (cards, headers, empty states, disclaimer)
│   └── utils/
│       └── app_theme.dart
│          └── Theme constants, colors, styles, shared app constants
├── assets/
│   ├── images/
│   ├── icons/
│   └── data/
│      └── medicines_v2.json
│         └── Medicine autocomplete runtime dataset
├── android/
│   └── Native Android config and Gradle setup
├── firestore.rules
│   └── Firestore security rules for role + pairing + permission model
├── firebase.json
│   └── Firebase CLI deployment config
├── pubspec.yaml
│   └── Flutter metadata, dependencies, asset declarations
└── .gitignore
   └── Secret/local/generated files ignore policy
```

## Architecture Notes

- Presentation layer: `lib/screens/*` and `lib/widgets/*`
- State layer: `lib/services/app_state.dart` (single source of truth)
- Integration layer: `lib/services/firebase_service.dart`, `ai_service.dart`, `notification_service.dart`
- Domain layer: `lib/models/models.dart`
- Static assets: `assets/*`

The app follows a practical stateful pattern where user actions update local state first and then sync to cloud/storage for responsive UX.

## Prerequisites

Before running the app, ensure you have:
- Flutter SDK installed
- Android Studio / Android SDK
- A configured emulator or physical device
- Firebase project (for auth and cloud features)

## Getting Started

### 1. Clone and open project

```bash
git clone <your-repo-url>
cd healthvault_ai
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Place Firebase Android config file at:
- `android/app/google-services.json`

Deploy Firestore rules:

```bash
firebase login
firebase use <project-id>
firebase deploy --only firestore:rules
```

### 4. Configure AI API key (optional)

Run with API key via dart-define:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=<your-key>
```

Without the key, AI features may use fallback behavior depending on implementation.

### 5. Run the app

```bash
flutter run
```

### 6. Static analysis

```bash
flutter analyze
```

## Build

### Debug APK

```bash
flutter build apk --debug
```

### Release APK

```bash
flutter build apk --release
```

## Core Features (Detailed)

### 1. Authentication and Roles
- Email/password sign-in and sign-up.
- Account type selection (`patient` or `guardian`) at signup.
- Terms and medical disclaimer acceptance required during onboarding.

### 2. Role-Based Access Control
- Patient is data owner.
- Guardian accesses patient data only after pairing and approval.
- Granular permission toggles:
   - view records
   - view medicines
   - manage medicines
   - receive emergency alerts

### 3. Family Pairing Workflow
- Patient generates invite code.
- Guardian submits link request using invite code.
- Patient approves/rejects request.
- Patient can unlink guardian later.

### 4. Documents and Reports
- Upload document (image/PDF depending on platform support).
- OCR extraction for readable text.
- Structured field extraction (doctor/patient/date/basic values when detected).
- AI summary generation and display with medical disclaimer.
- Search/filter and delete records.

### 5. AI Assistant
- AI document summary for uploaded records.
- AI chat for health-related support prompts.
- Safety messaging/disclaimer shown in AI surfaces.

### 6. Medicine Management
- Add medicines with dosage/frequency/duration/times.
- Dataset-backed autocomplete suggestions.
- Typo-tolerant medicine matching and ranked suggestions.
- Mark dose as taken for today.
- Delete and manage reminders.
- Overdue dose detection with visual alerts.
- Lightweight interaction risk flags.

### 7. Notifications
- Scheduled local medicine reminders.
- Emergency/SOS notification flow.
- Missed-dose alert notifications.
- Notification tray/home indicator integration.

### 8. Medical History and Insights
- Live activity dashboard (records, adherence, trends).
- Timeline of records, medicine actions, and appointments.
- Quick routes to analytics and appointment planner.

### 9. Appointments and Analytics
- Appointment add/list/delete/mark completed.
- Usage analytics cards and trend rows for engagement/activity.

### 10. Data Controls
- Export data to JSON file with resolved path feedback.
- Delete health data action for patient account.
- Audit logging for sensitive actions in Firestore.

## Environment and Secrets

Sensitive files and local configs should not be committed. Use `.gitignore` for:
- `.env`
- Firebase local config files
- Local logs and generated files

## Development Notes

- Main state orchestration is in `lib/services/app_state.dart`
- Backend integrations are in `lib/services/firebase_service.dart`
- UI flows are under `lib/screens/`
- Shared components live in `lib/widgets/`

## Troubleshooting

- If login/signup fails, verify Firebase Auth is enabled
- If Firestore operations fail, verify `firestore.rules` deployment
- If reminders are not shown, verify notification permissions on device
- If AI requests fail, verify API key and network connectivity

## Contributing

1. Create a feature branch
2. Make your changes
3. Run:
   - `flutter pub get`
   - `flutter analyze`
4. Commit with clear messages
5. Open a pull request

## License

This project is for academic/prototype use unless otherwise specified.

## Disclaimer

HealthVault is an assistive tool. AI outputs are informational and not medical advice. Always consult a licensed healthcare professional for diagnosis or treatment decisions.
