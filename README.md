# HealthVault — Flutter Prototype
## Team Tesla · PES University CIE

---

## 📁 Project Structure

```
healthvault_ai/
├── lib/
│   ├── main.dart                    ← Entry point
│   ├── models/
│   │   └── models.dart              ← AppUser, HealthDocument, MedicineReminder, etc.
│   ├── services/
│   │   ├── app_state.dart           ← Auth + global state (Provider)
│   │   ├── ai_service.dart          ← Gemini AI integration
│   │   └── notification_service.dart← Local push notifications
│   ├── utils/
│   │   └── app_theme.dart           ← Colors, typography, constants
│   ├── widgets/
│   │   └── shared_widgets.dart      ← Reusable UI components
│   └── screens/
│       ├── auth_screens.dart        ← Login + Signup
│       ├── terms_screen.dart        ← Terms & Conditions
│       ├── main_shell.dart          ← Bottom navigation shell
│       ├── dashboard_screen.dart    ← Home dashboard
│       ├── documents_screen.dart    ← Health records list + search
│       ├── upload_document_screen.dart ← Upload medical files
│       ├── ai_summary_screen.dart   ← AI document explanation
│       ├── medicine_screen.dart     ← Medicine reminders + autofill
│       ├── ai_chat_screen.dart      ← AI health chatbot
│       ├── medical_history_screen.dart ← Charts + AI insights + timeline
│       ├── guardian_dashboard_screen.dart ← Guardian view
│       ├── emergency_screen.dart    ← SOS emergency alert
│       └── profile_screen.dart      ← Profile + settings
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/.../MainActivity.kt
│   │       └── res/
│   ├── build.gradle
│   ├── settings.gradle
│   └── gradle.properties
└── pubspec.yaml
```

---

## ✅ Features Implemented

| Feature | Status |
|---|---|
| Login / Signup (Patient & Guardian) | ✅ |
| Terms & Conditions with Medical Disclaimer | ✅ |
| Document Upload (PDF/Image) | ✅ |
| Health Records Dashboard with Search & Filter | ✅ |
| AI Document Summary (Gemini API) | ✅ |
| Multilingual Support (EN/HI/TE/KN/TA) | ✅ |
| Voice Playback of Summary | ✅ (TTS ready) |
| Medicine Reminders with Autocomplete | ✅ |
| Dose Tracking (mark taken/pending) | ✅ |
| AI Health Chat Assistant | ✅ |
| Symptom Explainer with quick questions | ✅ |
| Medical History Timeline | ✅ |
| Health Charts (7-day trends) | ✅ |
| AI Health Insights & Meal Recommendations | ✅ |
| Emergency SOS Alert | ✅ |
| Guardian Dashboard | ✅ |
| Emergency Contacts Management | ✅ |
| Profile + Language Settings | ✅ |

---

## 🚀 Setup Guide (Linux + Android Studio)

### Step 1 — Install Flutter on Linux

```bash
# Download Flutter SDK
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz
tar xf flutter_linux_3.19.0-stable.tar.xz

# Add to PATH (add to ~/.bashrc)
export PATH="$PATH:$HOME/flutter/bin"
source ~/.bashrc

# Verify
flutter doctor
```

### Step 2 — Install Android Studio

```bash
# Download from: https://developer.android.com/studio
# Or via snap:
sudo snap install android-studio --classic

# Open Android Studio → SDK Manager → Install:
# - Android SDK Platform 34
# - Android SDK Build-Tools 34
# - Android Emulator
# - Android SDK Platform-Tools
```

### Step 3 — Create Emulator

```
Android Studio → Device Manager → Create Device
→ Pixel 6 (or any) → Android 14 (API 34)
→ Finish → Play button to start emulator
```

### Step 4 — Set up the Project

```bash
# Clone / copy this project folder
cd healthvault_ai

# Install dependencies
flutter pub get

# Verify setup
flutter doctor -v
```

### Step 5 — Firebase Setup (optional for full backend)

```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (create project at console.firebase.google.com first)
flutterfire configure --project=YOUR_PROJECT_ID

# This generates: lib/firebase_options.dart
# Then uncomment Firebase.initializeApp() in main.dart
```

### Step 6 — Add API Key Securely (Do Not Hardcode)

The app reads the key from compile-time environment:

- `OPENROUTER_API_KEY`

Get your key from OpenRouter and run with `--dart-define`:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=YOUR_OPENROUTER_KEY
```

Optional local-only setup for convenience (Linux/macOS):

```bash
# Add once to ~/.bashrc or ~/.zshrc
export OPENROUTER_API_KEY="YOUR_OPENROUTER_KEY"

# Reload shell
source ~/.bashrc

# Run app
flutter run --dart-define=OPENROUTER_API_KEY=$OPENROUTER_API_KEY
```

Security notes:

- Never commit real API keys to source code.
- Never paste keys into `lib/utils/app_theme.dart` or any tracked file.

### Step 7 — Run the App

```bash
# List connected devices / emulators
flutter devices

# Run demo mode (works without API key)
flutter run

# Run with AI enabled
flutter run --dart-define=OPENROUTER_API_KEY=YOUR_OPENROUTER_KEY

# Run on specific device
flutter run -d emulator-5554

# Build APK for sharing
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

---

## 🔑 Demo Mode

The app runs **fully in demo mode** without any API keys or Firebase setup:

- **Login**: Any email + any 6+ character password
- **AI Summaries**: Returns realistic mock medical report summaries
- **AI Chat**: Returns helpful mock health responses
- **All screens**: Fully navigable with realistic sample data

---

## 🔧 Key Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `firebase_auth` | Authentication |
| `cloud_firestore` | Database |
| `firebase_storage` | File storage |
| `flutter_animate` | Smooth animations |
| `fl_chart` | Health trend charts |
| `flutter_local_notifications` | Medicine reminders |
| `flutter_tts` | Voice playback |
| `speech_to_text` | Voice input |
| `file_picker` | Document upload |
| `google_fonts` | Typography (Poppins) |
| `http` | Gemini API calls |

---

## 📱 Screen Flow

```
App Launch
  └─ Not logged in → LoginScreen
       ├─ SignupScreen → TermsScreen → MainShell
       └─ LoginScreen → MainShell
            ├─ Tab 1: DashboardScreen
            │    ├─ EmergencyScreen (SOS)
            │    └─ UploadDocumentScreen
            ├─ Tab 2: DocumentsScreen
            │    ├─ UploadDocumentScreen
            │    └─ AISummaryScreen
            ├─ Tab 3: MedicineScreen
            │    └─ AddMedicineSheet (bottom sheet)
            ├─ Tab 4: AIChatScreen
            └─ Tab 5: ProfileScreen
```

---

## 🎨 Design Principles (Elderly-Friendly)

- **Font size**: Minimum 13px, most text 15-16px
- **Button height**: 60px minimum (big tap targets)
- **Color contrast**: High contrast blue/white/green palette
- **Icons**: Large, clear, labeled
- **Navigation**: Simple 5-tab bottom bar, always visible
- **Animations**: Smooth but not distracting
- **Error states**: Clear, friendly messages
- **Language**: Simple words, no medical jargon in UI

---

## ⚕️ Medical Disclaimer

> AI-generated summaries, explanations, and voice responses are NOT medical diagnoses.
> Always consult a qualified doctor before making any medical decisions.

This disclaimer appears on:
- Terms & Conditions page (mandatory acceptance)
- Every AI summary
- Every AI chat response
- The AI Insights dashboard

---

*Built by Team Tesla · PES University CIE · Phase 2 Prototype*
