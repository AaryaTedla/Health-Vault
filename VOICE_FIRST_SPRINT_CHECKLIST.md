# Voice-First Sprint Checklist (7 Days)

Goal: ship a reliable Android demo where elderly users can use major app features by voice in English and Hindi, with tunnel-first AI inference and cloud fallback.

## Scope Lock

In scope:

- Android only
- English + Hindi voice
- Voice access to major flows: dashboard navigation, medicines, appointments, documents, emergency, guardian status, profile summary
- Tunnel/local model server as primary inference path

Out of scope (this sprint):

- Full on-device multimodal model packaging
- iOS support
- Large refactors unrelated to demo reliability
- Full automated test suite coverage

## Definition of Done

1. User can complete critical flows by voice in English and Hindi.
2. Emergency voice trigger is deterministic and safe.
3. AI calls route tunnel-first; cloud fallback works and is capped.
4. App handles common failures gracefully (network, timeout, STT/TTS unavailable).
5. Demo script runs end-to-end on one primary and one backup Android device.

## Day 1: Reliability Baseline (Must Not Skip)

### Tasks

- [ ] Freeze current state and create working branch.
- [ ] Identify and fix async sequencing issues around auth warmup and sign-out in `lib/services/app_state.dart`.
- [ ] Verify timer lifecycle for live location and guardian polling in `lib/services/app_state.dart`.
- [ ] Ensure timer cancellation and state cleanup are guaranteed on role switch/logout.
- [ ] Replace silent error swallowing with typed/surfaceable errors in `lib/services/firebase_service.dart`.

### Exit Criteria

- [ ] No visible race where UI renders empty indefinitely after login.
- [ ] No duplicated location polling/timer leak after login-logout-login.
- [ ] Firebase write failures produce user-visible message and debug log.

## Day 2: AI Routing Foundation (Tunnel First)

### Tasks

- [ ] Introduce provider abstraction in `lib/services/ai_service.dart`:
  - `TunnelProvider` (default)
  - Existing cloud provider (fallback)
  - `OnDeviceProvider` stub (future)
- [ ] Add routing policy: tunnel first, fallback only on failure/timeout.
- [ ] Add explicit timeout and retry policy for tunnel requests.
- [ ] Add per-day fallback cap and logging of provider used.
- [ ] Add a lightweight connection status indicator in chat/voice surfaces.

### Exit Criteria

- [ ] Successful prompt returns from tunnel path.
- [ ] On forced tunnel failure, cloud fallback triggers once and logs reason.
- [ ] If cap reached, fallback is blocked with clear UI message.

## Day 3: Voice Core State Machine

### Tasks

- [ ] Create `lib/services/voice_agent_service.dart` with state machine:
  - `idle -> listening -> transcribing -> confirming -> executing -> speaking -> idle`
- [ ] Add voice session model in `lib/models/models.dart` (or dedicated model file): intent, confidence, language, timestamps, outcome.
- [ ] Add cancel/retry/repeat-last-response handlers.
- [ ] Add centralized voice error mapping (mic denied, STT timeout, no speech, TTS failure).

### Exit Criteria

- [ ] Voice session can start/stop reliably without app restart.
- [ ] State transitions are deterministic under normal and timeout conditions.
- [ ] Error states always return user to a usable state.

## Day 4: Intent Layer + App Action Dispatch

### Tasks

- [ ] Add `lib/services/voice_intent_router.dart` mapping intents to existing `AppState`/screen actions.
- [ ] Implement intents for:
  - Navigation (open medicines, documents, appointments, emergency, chat, profile)
  - Medicines (list, next dose, mark taken, add basic reminder)
  - Appointments (list upcoming, add simple appointment)
  - Documents (list latest, open summary)
  - Guardian (status summary)
  - Emergency (trigger flow)
- [ ] Add mandatory confirmation for high-risk intents (emergency, edit/delete, medication changes).

### Exit Criteria

- [ ] At least 20 core voice commands execute correctly in English.
- [ ] High-risk actions require explicit confirmation.
- [ ] Cancel command stops action before mutation.

## Day 5: English + Hindi Support and UX for Elderly

### Tasks

- [ ] Add bilingual command phrase packs and synonyms in `lib/services/voice_intents_en_hi.dart`.
- [ ] Wire STT/TTS language selection to app language/user setting in `lib/services/app_state.dart`.
- [ ] Add fallback: if Hindi STT/TTS fails, retry in English with clear prompt.
- [ ] Add universal voice entry affordance in `lib/screens/main_shell.dart`.
- [ ] Add large caption/confirmation UI component in `lib/widgets/shared_widgets.dart` (or new widget file).

### Exit Criteria

- [ ] 20 core commands work in Hindi and English.
- [ ] Captions are readable; confirmations are high-contrast and large.
- [ ] Users can complete actions with voice or touch fallback.

## Day 6: Screen Integration + Safety Guardrails

### Tasks

- [ ] Integrate voice responses into:
  - `lib/screens/medicine_screen.dart`
  - `lib/screens/documents_screen.dart`
  - `lib/screens/appointment_screen.dart`
  - `lib/screens/emergency_screen.dart`
  - `lib/screens/guardian_dashboard_screen.dart`
- [ ] Add medical safety prompts and non-diagnostic framing in AI responses via `lib/services/ai_service.dart`.
- [ ] Ensure emergency keywords preempt regular chat and route to emergency flow.
- [ ] Log voice actions and outcomes via `lib/services/audit_service.dart`.

### Exit Criteria

- [ ] Emergency trigger works from any screen with predictable behavior.
- [ ] No unsafe direct execution for high-risk actions.
- [ ] Audit entries capture voice action, intent, result, and failures.

## Day 7: Hardening + Demo Rehearsal

### Tasks

- [ ] Run bilingual manual test matrix (quiet and noisy environment).
- [ ] Failure drills:
  - Tunnel down
  - Cloud fallback disabled/capped
  - STT unavailable
  - TTS unavailable
  - Firebase offline
- [ ] Finalize demo configuration and backup toggles.
- [ ] Prepare two demo scripts:
  - Primary (full network)
  - Backup (degraded mode)

### Exit Criteria

- [ ] Demo can continue under at least 3 degraded scenarios.
- [ ] Team has run at least 2 full rehearsals on real devices.
- [ ] Known issues list is short, documented, and avoidable during demo.

## File-Level Implementation Targets

Core:

- `lib/services/app_state.dart`
- `lib/services/firebase_service.dart`
- `lib/services/ai_service.dart`
- `lib/services/audit_service.dart`

New recommended files:

- `lib/services/voice_agent_service.dart`
- `lib/services/voice_intent_router.dart`
- `lib/services/voice_intents_en_hi.dart`

UI integration:

- `lib/screens/main_shell.dart`
- `lib/screens/ai_chat_screen.dart`
- `lib/screens/medicine_screen.dart`
- `lib/screens/documents_screen.dart`
- `lib/screens/appointment_screen.dart`
- `lib/screens/emergency_screen.dart`
- `lib/screens/guardian_dashboard_screen.dart`
- `lib/widgets/shared_widgets.dart`

Android bridge (if required by plugin/runtime choice):

- `android/app/src/main/kotlin/com/teamtesla/healthvault/MainActivity.kt`

## Command Accuracy Gate (Must Pass)

English:

- [ ] 20/20 critical commands understood with confirmation for risky actions.

Hindi:

- [ ] 18/20 critical commands understood (or clear retry path offered).

Safety:

- [ ] 100% emergency commands route to emergency confirmation/execution flow.
- [ ] 0 accidental high-risk mutations without confirmation.

## Daily Standup Template (Use During Sprint)

- Yesterday done:
- Today target:
- Blockers:
- Demo risk level: Low / Medium / High
- Fallback readiness: Ready / Partial / Not ready

## Demo Day Checklist

- [ ] Tunnel URL and token verified.
- [ ] Backup tunnel/API key present.
- [ ] Device battery > 70% and charger available.
- [ ] Microphone and speaker permissions granted.
- [ ] Emergency contacts configured in app.
- [ ] One printed command cheat sheet (English/Hindi).
- [ ] One backup flow if STT quality degrades.
