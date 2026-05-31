# Wardly — Project Context for Claude

## What is Wardly
A real-time clinical notes app for hospital ward teams. Built with Flutter + Firebase. Available on Android (Play Store), iOS (App Store via Codemagic), and Web (Firebase Hosting / GitHub Pages).

**Developer:** Sunil Mulgund (mulgundsunil@gmail.com)  
**Personal site:** https://bridgr.co.in  
**Support link:** https://bridgr.co.in/support?from=wardly  
**Landing page:** https://wardly.bridgr.co.in  
**Web app:** https://wardlyapp.bridgr.co.in  
**Status page:** https://wardly.bridgr.co.in/status/  
**Firebase project:** wardly-24081996  
**Bundle ID (Android + iOS):** com.wardly.app  
**GitHub repo:** private  

---

## Tech Stack
- **Flutter** (Dart) — cross-platform (Android, iOS, Web)
- **Firebase Auth** — Email/password + Google Sign-In + Apple Sign-In (iOS)
- **Cloud Firestore** — real-time database
- **Firebase Cloud Messaging (FCM)** — push notifications
- **Firebase Hosting** — web app + landing page
- **Provider** — state management (AuthProvider, NoteProvider, PatientProvider)
- **Google Fonts** — DM Sans throughout
- **showcaseview** — first-run coachmark tour
- **in_app_review** — weekly Play Store review nudge
- **sign_in_with_apple** — iOS-only Apple Sign-In
- **Codemagic** — CI/CD for iOS builds (mac_mini_m2)

---

## User Roles
- **Doctor** — home, wards, patients, notes feed, profile (5 tabs)
- **Nurse** — home, wards, patients, profile (4 tabs)
- **Admin** — dashboard analytics, wards, staff list, profile (4 tabs)

---

## Key Architecture Decisions
- **Ward codes** are 5-digit numeric (atomic transaction, collision-retry) — NOT UUIDs
- **Streams are lifecycle-managed** — paused on app background, resumed on foreground (saves Firestore cost)
- **All queries are capped** — notes limit(150), unack limit(150), comments limit(100), patients limit(200)
- **Batch cascade deletes** — deleting a patient/ward deletes all sub-collections in batches of 500
- **count() aggregation** used in admin dashboard (not full document reads)
- **Metrics doc** at `metrics/totals` — incremented by Cloud Functions, read by landing page live stats
- **SharedPreferences keys are versioned** (e.g. `onboarding_complete_v2`, `interactive_tutorial_done_v1`) to survive Samsung Smart Switch restores

---

## Important File Locations

### Screens
- `lib/screens/auth/login_screen.dart` — Email/Google/Apple sign-in, forgot password with pre-check
- `lib/screens/auth/onboarding_screen.dart` — 4-slide tutorial (problem → Wardly → how it works → get started), key: `onboarding_complete_v2`
- `lib/screens/auth/splash_screen.dart` — auth gate, reads versioned onboarding key
- `lib/screens/shared/main_scaffold.dart` — bottom nav, ShowCaseWidget coachmark wrapper, lifecycle observer
- `lib/screens/shared/profile_screen.dart` — settings, dark mode, text size, feedback, rate app, About (bridgr.co.in)
- `lib/screens/shared/help_screen.dart` — 15 FAQ collapsible tiles
- `lib/screens/shared/wards_screen.dart` — create/join/leave/delete wards, 5-digit codes, members sheet
- `lib/screens/doctor/add_note_screen.dart` — new note bottom sheet, ward picker uses whereIn
- `lib/screens/doctor/add_patient_screen.dart` — add patient, ward picker uses whereIn
- `lib/screens/admin/admin_home_screen.dart` — analytics dashboard, 10 cards using count() aggregation

### Widgets
- `lib/widgets/note_card.dart` — note display with priority, ack badge, delete
- `lib/widgets/note_comments_sheet.dart` — thread bottom sheet; resizeToAvoidBottomInset:false (keyboard fix)
- `lib/widgets/support_action.dart` — SupportAppBarAction (top-right in every AppBar)
- `lib/widgets/support_sheet.dart` — support bottom sheet → bridgr.co.in/support?from=wardly

### Services
- `lib/services/auth_service.dart` — signInWithGoogle, signInWithApple (iOS), sendPasswordReset with ActionCodeSettings
- `lib/services/note_service.dart` — CRUD, limit(150), acknowledgeNote, unacknowledgeNote
- `lib/services/patient_service.dart` — CRUD, batched _deleteNotesFor, limit(200)
- `lib/services/push_service.dart` — FCM registration/unregistration, static listener vars

### Providers
- `lib/providers/auth_provider.dart` — wraps AuthService, exposes currentUser (AppUser)
- `lib/providers/note_provider.dart` — subscribeForWards, pauseStreams, unacknowledgedCount
- `lib/providers/patient_provider.dart` — subscribeForWards, pauseStream

### Utils
- `lib/utils/app_theme.dart` — AppColors (primary, surface, card, danger, etc.), light/dark theme
- `lib/utils/share_helper.dart` — share message, web URL = wardly-24081996.web.app
- `lib/utils/rate_prompt.dart` — weekly in_app_review with SharedPreferences guard

### Models
- `lib/models/app_user.dart` — AppUser with UserRole enum (doctor, nurse, admin)
- `lib/models/note.dart` — Note with priority, acknowledgements, wardId, patientId
- `lib/models/patient.dart` — Patient with bedNumber, wardId
- `lib/models/ward.dart` — Ward with 5-digit code, creatorId, memberIds

### Config
- `android/app/build.gradle.kts` — applicationId com.wardly.app, targetSdk 35, release signing
- `android/app/src/main/AndroidManifest.xml` — allowBackup=false
- `android/app/google-services.json` — has SHA-1 + SHA-256 for upload key AND Play App Signing key
- `ios/Runner/Info.plist` — permissions, LSApplicationQueriesSchemes, REVERSED_CLIENT_ID, ITSAppUsesNonExemptEncryption=false
- `ios/Runner/Runner.entitlements` — aps-environment (production), com.apple.developer.applesignin
- `ios/Runner/GoogleService-Info.plist` — Firebase iOS config for com.wardly.app
- `ios/Podfile` — platform :ios, '13.0'
- `codemagic.yaml` — ios-release workflow (mac_mini_m2, App Store Connect integration)
- `firestore.rules` — get vs list split, ward membership checks, creator-only update/delete
- `functions/index.js` — Cloud Functions: COMMON_OPTS (256MiB, minInstances:0), backfillMetrics

### Landing / Web
- `landing/index.html` — marketing page (problem → solution → how it works → live stats)
- `landing/privacy.html` — full privacy policy
- `landing/style.css` — landing page styles
- `landing/status/index.html` — public status page (one-shot Firestore read, NOT onSnapshot)

---

## Android Signing
- **Keystore file:** `wardly-upload-key.jks` (keep safe, NOT in git)
- **key.properties:** in `android/` folder (NOT in git)
- Both SHA-1 and SHA-256 registered in Firebase Console for com.wardly.app Android app
- Play App Signing is active — Play re-signs with their own key for distribution

## iOS Signing
- **iOS Bundle ID: `com.wardlyapple.app`** (NOTE: differs from Android `com.wardly.app` — confirmed in `ios/Runner.xcodeproj/project.pbxproj` + `GoogleService-Info.plist`)
- Codemagic handles provisioning profiles automatically via App Store Connect API key
- APNs Auth Key (.p8): **Key ID `NUMA3S765L`, Team ID `SR35PG294W`**, team-scoped (all topics), Sandbox & Production. Uploaded to Firebase Console → Cloud Messaging → Apple app config in BOTH Development and Production slots.
- APP_STORE_APPLE_ID in codemagic.yaml: update once App Store Connect entry is created (currently placeholder `0000000000`)

### ⚠️ CRITICAL iOS PUSH GOTCHA — aps-environment must be `production`
- `ios/Runner/Runner.entitlements` → `aps-environment` **MUST be `production`** for any TestFlight/App Store build.
- **Why:** Codemagic signs with the literal entitlements file — it does NOT do the Xcode-archive auto-flip from development→production. A distribution-signed binary carrying `aps-environment: development` makes iOS refuse remote-notification registration → no APNs token → `FirebaseMessaging.getToken()` throws → `PushService` swallows it → `fcmTokens` never written to the user doc → Cloud Function has nothing to send → **no notifications on iOS** (in-app FCM banners still work since those skip APNs).
- `production` works for BOTH TestFlight and App Store. Never set it back to `development`.
- **Android is unaffected** by this — Android push goes FCM→Google Play Services directly, never touches APNs. So "works on Android, not iOS" is the signature symptom of this bug.
- Fixed in commit (May 2026), version bumped to `1.5.1+21`. Requires a new build + users updating before it takes effect (entitlement is compiled into the binary).

---

## Design System
- **Primary colour:** #0A5C8A (deep blue)
- **Danger:** red (AppColors.danger)
- **Font:** DM Sans (Google Fonts)
- **Icons:** Material Icons
- **Theme:** light + dark mode supported via AppColors (context-aware)

---

## Play Store
- **Package:** com.wardly.app
- **Category:** Productivity (NOT Medical — individual account restriction)
- **Current version:** 1.4.0+17
- Play App Signing active, upload key separate

## App Store (iOS) — TODO
- [ ] Enroll in Apple Developer Program (developer.apple.com/enroll — ₹8,399/yr)
- [ ] Register com.wardly.app in Apple Developer → Identifiers with Push Notifications + Sign In with Apple
- [ ] Create app in App Store Connect → note the numeric Apple ID → update codemagic.yaml
- [ ] Generate APNs Auth Key (.p8) → upload to Firebase Console → Cloud Messaging
- [ ] First Codemagic build → TestFlight

---

## Known Gotchas
- Ward picker in add_note / add_patient uses `whereIn: myWardIds` — do NOT remove or security rules will block it
- Note comments sheet uses `resizeToAvoidBottomInset: false` — keyboard handling is manual; do not add Padding(viewInsets) or buttons become unreachable
- SharedPreferences keys are versioned — changing the key name triggers re-show of that tutorial/onboarding
- `count()` aggregation in admin dashboard — Firestore only supports this on server-side; do not replace with `.get().then(snap => snap.docs.length)` (too expensive)
- Apple Sign-In button is gated: `if (Platform.isIOS)` — never show on Android/Web
- `google-services.json` has TWO SHA entries — if you ever regenerate the keystore, both upload key SHA and Play App Signing SHA must be re-registered

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- ALWAYS read graphify-out/GRAPH_REPORT.md before reading any source files, running grep/glob searches, or answering codebase questions. The graph is your primary map of the codebase.
- IF graphify-out/wiki/index.md EXISTS, navigate it instead of reading raw files
- For cross-module "how does X relate to Y" questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"` over grep — these traverse the graph's EXTRACTED + INFERRED edges instead of scanning files
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
