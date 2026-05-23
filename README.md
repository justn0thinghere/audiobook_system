# Audiobook for Autism

An autism-friendly audiobook system for children, with a separate caregiver dashboard for content management, profiles, and listening insights. Built as a Flutter mobile app backed by a Laravel REST API.

The child-side experience focuses on **calm pacing, predictable navigation, and a real storybook feel** — pages with embedded illustrations, gentle book-flip transitions, and synchronised word highlighting that follows the narrator's voice so the child can read along.

---

## Table of Contents

1. [Highlights](#highlights)
2. [Architecture](#architecture)
3. [Modules](#modules)
4. [Tech Stack](#tech-stack)
5. [Project Structure](#project-structure)
6. [Prerequisites](#prerequisites)
7. [Backend Setup (Laravel)](#backend-setup-laravel)
8. [Frontend Setup (Flutter)](#frontend-setup-flutter)
9. [Testing on a Physical Phone](#testing-on-a-physical-phone)
10. [Building a Release APK](#building-a-release-apk)
11. [Database Schema](#database-schema)
12. [REST API Reference](#rest-api-reference)
13. [In-App User Flow](#in-app-user-flow)
14. [Troubleshooting](#troubleshooting)

---

## Highlights

- **Two user modes in one app** — a calm child mode and a full caregiver dashboard, gated by a 4-digit Guardian PIN.
- **Storybook reading experience** — sentence-based pagination, embedded illustration per page, 3-D book-flip transitions (with reduced-motion fallback), and a synchronised word-by-word highlight while the narrator speaks.
- **Dual playback path** — pre-recorded audio files via `just_audio` or live on-device narration via `flutter_tts`, with four pitch-differentiated narrator voices.
- **Caregiver insights** — per-child listening minutes, favourite genre, daily mood, engagement summary.
- **UUID-first data model** — every business entity (caregiver, child, setting, history) uses a 36-character UUID primary key.
- **Autism-friendly UI primitives** — large touch targets, soft pastel palette, themed `AppSnackbar`, optional reduced animations and read-along switches.

---

## Architecture

```
   ┌───────────────────────────────┐               ┌──────────────────────────────┐
   │  Flutter app (frontend/)      │   HTTPS/HTTP  │  Laravel API (backend/)      │
   │                               │  ──────────►  │                              │
   │  • Provider state             │     JSON      │  • Session middleware        │
   │  • Named routes + nav service │  ◄──────────  │  • UUID Eloquent models      │
   │  • flutter_tts + just_audio   │   Bearer tkn  │  • Mysql (XAMPP)             │
   └───────────────────────────────┘               └──────────────────────────────┘
```

- Authentication is **PIN-based** — caregiver registers with a 4-digit PIN; the backend hashes it with bcrypt and issues a 24-hour sliding session token.
- The Flutter app stores the session token in `SharedPreferences` and attaches it as a Bearer header on every protected request.
- All audio synthesis runs **on-device** through `flutter_tts`. No external speech API is contacted.

---

## Modules

| Module | Responsibility |
|---|---|
| **M1 Authentication & Session** | Caregiver registration, PIN login, PIN change, Guardian-PIN gate on Child-Mode exit. |
| **M2 Profile Management** | Create / view / update / delete child profiles (avatar emoji, age, favourite genre). |
| **M3 Personalization Settings** | Narrator voice, reading speed, volume, reduced animations, auto-play next, read-along. |
| **M4 Content Management** | Upload story content (text + optional audio + cover), search & filter the library. |
| **M5 Audio Playback & Storybook** | Sentence-paginated storybook UI, book-flip transitions, dual playback path, read-along word highlighting. |
| **M6 Listening Insights & Mood** | Record session metadata (duration, position, mood, completion), surface per-child insights for caregivers. |

---

## Tech Stack

**Frontend (`frontend/`)**
- Flutter 3 / Dart 3
- `provider` for state management
- `flutter_tts` for text-to-speech narration + word offsets
- `just_audio` + `audio_session` for prerecorded audio
- `http` for REST calls
- `shared_preferences` + `flutter_secure_storage` for session persistence
- `google_fonts` (Nunito) for typography
- `pin_code_fields` for PIN entry UI

**Backend (`backend/`)**
- PHP 8.2+ / Laravel 11
- MySQL via XAMPP
- UUIDs via Laravel's `HasUuids` trait
- Custom session-token middleware (no Sanctum)

---

## Project Structure

```
audiobook_system/
├── backend/                      ← Laravel API
│   ├── app/
│   │   ├── Models/               ← Caregiver, ChildProfile, CaregiverSettings,
│   │   │                            Audiobook, ListeningHistory
│   │   └── Http/
│   │       ├── Controllers/Api/  ← AuthController, ChildProfileController, …
│   │       └── Middleware/       ← SessionAuthMiddleware
│   ├── database/migrations/      ← UUID-based schema (4 tables)
│   └── routes/api.php            ← All `/api/*` endpoints
│
├── frontend/                     ← Flutter mobile app
│   └── lib/
│       ├── config/               ← API base URL
│       ├── navigation/           ← AppNavigationService + AppRoutes
│       ├── models/               ← JSON shapes mirroring backend resources
│       ├── services/             ← DatabaseService (REST client)
│       ├── state/                ← AuthState, ProfilesState, SettingsState
│       ├── theme/                ← AppColors + AppTheme (Nunito)
│       ├── widgets/              ← SoftCard, SoftChip, BackPill, StatCard,
│       │                            AppSnackbar
│       ├── audio/                ← AudioEngine wrapper around just_audio
│       └── pages/
│           ├── shared/           ← AuthGate, LoginPage, GuardianPinDialog
│           ├── caregiver/        ← Dashboard, Profiles, Content, Insights,
│           │                       Settings, UploadContent, AddChildDialog
│           └── child/            ← ChildShell, ChildHome, StoryLibrary,
│                                   AudioPlayerPage
│
└── README.md                     ← This file
```

---

## Prerequisites

- **PHP 8.2+** and **Composer** — bundled with XAMPP on Windows.
- **MySQL 5.7+** — bundled with XAMPP.
- **Flutter 3.x** — `flutter doctor` should report no critical errors.
- **Android Studio** with an emulator, **or** a physical Android phone with USB debugging enabled.
- (Optional) **VS Code** with Dart / Flutter and PHP extensions.

---

## Backend Setup (Laravel)

```powershell
cd c:\xampp\htdocs\audiobook_system\backend

# 1. Install PHP dependencies
composer install

# 2. Copy the env file and generate an app key
copy .env.example .env
php artisan key:generate

# 3. Create the database in phpMyAdmin (http://localhost/phpmyadmin)
#    Name: autism_audiobook

# 4. Edit .env — set DB credentials:
#       DB_DATABASE=autism_audiobook
#       DB_USERNAME=root
#       DB_PASSWORD=

# 5. Run migrations (creates caregivers, child_profiles,
#    caregiver_settings, listening_history, audiobooks)
php artisan migrate:fresh

# 6. Start the API bound to your LAN so a phone can reach it
php artisan serve --host=0.0.0.0 --port=8000
```

---

## Frontend Setup (Flutter)

```powershell
cd c:\xampp\htdocs\audiobook_system\frontend

# 1. Install Dart/Flutter dependencies
flutter pub get

# 2. Tell the app where the API lives — edit lib/config/app_config.dart
#    For an Android emulator: http://10.0.2.2:8000/api
#    For a physical phone on the same Wi-Fi: http://<your-pc-LAN-IP>:8000/api

# 3. Confirm a device is connected
flutter devices

# 4. Run on the connected device (debug)
flutter run

# OR run a release build directly to the connected device
flutter run --release
```

---

## Testing on a Physical Phone

1. Confirm the phone and the PC are on the **same Wi-Fi network**.
2. On the PC, find the Wi-Fi adapter's IPv4 address:
   ```powershell
   ipconfig
   ```
3. Put that IP in [frontend/lib/config/app_config.dart](frontend/lib/config/app_config.dart):
   ```dart
   static const String databaseApiUrl = 'http://192.168.x.x:8000/api';
   ```
4. Start the API bound to all interfaces:
   ```powershell
   cd c:\xampp\htdocs\audiobook_system\backend
   php artisan serve --host=0.0.0.0 --port=8000
   ```
5. Open Windows Firewall once (run PowerShell as Administrator):
   ```powershell
   New-NetFirewallRule -DisplayName "Laravel Dev 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow
   ```
6. On the phone's browser, visit `http://<your-PC-IP>:8000` — the Laravel welcome page should appear. If it doesn't, the firewall is still blocking.
7. Run `flutter run --release` with the phone connected over USB.

The Android manifest already grants `INTERNET` permission and sets `usesCleartextTraffic="true"`, so plain-HTTP LAN traffic works on Android 9+.

---

## Building a Release APK

```powershell
cd c:\xampp\htdocs\audiobook_system\frontend

# Single universal APK
flutter build apk --release

# Smaller per-architecture APKs
flutter build apk --release --split-per-abi
```

Output lands in `build\app\outputs\flutter-apk\`. Copy the APK to the phone, allow "Install unknown apps" in the file-manager settings, and tap the file.

---

## Database Schema

All tables use **UUID (`char(36)`) primary keys**.

| Table | Primary key | Notable foreign keys | Purpose |
|---|---|---|---|
| `caregivers` | `caregiver_id` | — | Caregiver accounts; bcrypt-hashed PIN, session token, sliding expiry. |
| `child_profiles` | `child_id` | `caregiver_id` | Each child supervised by a caregiver. |
| `caregiver_settings` | `setting_id` | `caregiver_id` (unique) | Narrator voice, reading speed, volume, reduced animations, auto-play, read-along. |
| `listening_history` | `history_id` | `child_id`, `audiobook_id` | One row per listening session; duration, position, mood, completion. |
| `audiobooks` | `audiobook_id` | — | Story content; title, body text, optional audio/cover file paths, AI flag. |

All foreign keys use `ON DELETE CASCADE`. Deleting a caregiver cleans the entire family tree of profiles, settings, and history.

---

## REST API Reference

Base URL: `http://<host>:8000/api`. Every request is `POST` (multipart only for uploads), returns JSON of shape:

```jsonc
{ "status": "SUCCESS" | "ERROR",
  "message": "...",
  "data": { ... },
  "error_code": "OPTIONAL",
  "timestamp": "YYYY-MM-DD HH:mm:ss" }
```

**Public**
| Method | Path | Purpose |
|---|---|---|
| POST | `/test` | Health check. |
| POST | `/auth/register` | Create a caregiver, returns session token + caregiver profile. |
| POST | `/auth/login` | PIN login, returns session token. |

**Protected** — require `Authorization: Bearer <session_token>`.
| Method | Path | Purpose |
|---|---|---|
| POST | `/auth/me` | Current caregiver. |
| POST | `/auth/logout` | Invalidate token. |
| POST | `/auth/verify-pin` | Used by the Guardian PIN dialog. |
| POST | `/settings/` | Get caregiver settings. |
| POST | `/settings/update` | Patch settings (partial). |
| POST | `/settings/change-pin` | Replace PIN. |
| POST | `/child-profiles/` | List children for the caregiver. |
| POST | `/child-profiles/create` | Add a child. |
| POST | `/child-profiles/{childId}/update` | Update a child (UUID-constrained). |
| POST | `/child-profiles/{childId}/delete` | Delete a child. |
| POST | `/audiobooks/{audiobookId}` | Fetch one audiobook. |
| POST | `/content/summary` | Library totals by type. |
| POST | `/content/list` | Search / filter content. |
| POST | `/content/create` | Upload content (multipart). |
| POST | `/listening-history/record` | Persist a session. |
| POST | `/listening-history/child/{childId}` | Last 50 sessions for a child. |

---

## In-App User Flow

1. **First launch** — the user lands on the Login screen. Tap *Create a caregiver account* to register.
2. **Caregiver Dashboard** — top-level totals, list of child profiles, and a prominent red *Logout* button.
3. **Profiles tab** — add / edit / remove children.
4. **Content tab** — upload stories, browse the library by type / age, view content totals.
5. **Insights tab** — engagement, listening minutes, most-felt mood, per-child summary cards.
6. **Settings tab** — narrator voice, reading speed, volume, reduced animations, auto-play next, **read-along**, PIN change.
7. **Enter Child Mode** — tap *Enter Child Mode* on a profile card → the app switches to the Child Shell.
8. **Child Home** — daily mood selection, *Continue Listening*, and *Browse Story Library*.
9. **Story Library** — search by title, filter by category / age range.
10. **Audio Player** — sentence-paginated storybook with cover illustration, big *Listen* button, narrator dropdown, word-by-word read-along highlight, swipe to flip pages.
11. **Exit Child Mode** — tap the *Exit* tab → Guardian PIN dialog appears → enter the caregiver's PIN to return to the Caregiver Dashboard.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| **`SQLSTATE[42S02] ... 'caregivers' doesn't exist`** | You haven't run the migrations. `php artisan migrate:fresh` from `backend/`. |
| **Login screen never connects** | Phone can't reach the PC's IP. Visit `http://<pc-ip>:8000` on the phone's browser to verify, then open the firewall (see [Testing on a Physical Phone](#testing-on-a-physical-phone)). |
| **Tap Listen — no voice** | Device has no TTS engine installed, or device volume is at 0. Try *Settings → Accessibility → Text-to-speech output* on Android. The snackbar in-app will hint at this. |
| **"Cleartext HTTP not permitted"** | Only an issue on custom builds; the bundled manifest already enables it. If you changed the manifest, restore `android:usesCleartextTraffic="true"`. |
| **Phone shows a raw SQL error in a snackbar** | `APP_DEBUG=true` in `backend/.env` leaks the SQL exception. Set `APP_DEBUG=false` for friendlier "Server Error" messages. |
| **`audiobooks` table doesn't exist** | Run `php artisan migrate` — the audiobooks table is in `2025_05_16_000004_create_audiobooks_table.php`. Use plain `migrate` (not `migrate:fresh`) so your caregiver account survives. |

---

## Academic Context

This system was developed as a Final Year Project investigating **AI-supported audiobook delivery for autistic learners**. The system analysis and design (use case diagram, module breakdown, functional requirements) is documented separately in the project report; the present README focuses on the deliverable software.

The **Gemini AI integration** for caregiver-uploaded text → narration audio (`is_generated` flag on the audiobooks table) is scaffolded but not wired to a live API in this build — it is documented as planned future work in the project report.
