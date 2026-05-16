# Audiobook for Autism — Monorepo

Autism-friendly audiobook system for children and caregivers. This repository
holds both the Flutter mobile app and the Laravel API in a single workspace so
they can be developed side by side in VSCode.

```
audiobook_backend/
├── backend/    # Laravel 11 API (PHP)
└── frontend/   # Flutter mobile app (Dart)
```

---

## Backend — Laravel API

Path: [backend/](backend/)

The Laravel app exposes a small JSON API used by the Flutter client.
Endpoints currently implemented (all `POST`):

| Path                          | Purpose                              |
|-------------------------------|--------------------------------------|
| `/api/test`                   | Routing health-check                 |
| `/api/audiobooks/{id}`        | Fetch a single audiobook by UUID     |
| `/api/content/summary`        | Counts: total / audio / text / AI    |
| `/api/content/list`           | Paginated content list with filters  |
| `/api/content/create`         | Caregiver upload of new content      |

### Running the backend

The folder lives under `c:\xampp\htdocs\audiobook_backend\backend\`, so XAMPP
will serve it at `http://localhost/audiobook_backend/backend/public/`. For
mobile development we recommend `artisan serve` so the URL stays simple:

```powershell
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

Android emulator reaches the host loopback through `10.0.2.2`, so the Flutter
client points at `http://10.0.2.2:8000/api` by default
([frontend/lib/config/app_config.dart](frontend/lib/config/app_config.dart)).

If you prefer to keep using XAMPP Apache, change `databaseApiUrl` to
`http://10.0.2.2/audiobook_backend/backend/public/api`.

---

## Frontend — Flutter app

Path: [frontend/](frontend/)

### Run

```powershell
cd frontend
flutter pub get
flutter run
```

### Project structure

```
frontend/lib/
├── main.dart                       # Entry point + Provider setup
├── audio/audio_engine.dart         # just_audio wrapper (play/pause/seek/speed)
├── config/app_config.dart          # API URL + app constants
├── models/                         # Audiobook, ChildProfile, ContentItem
├── services/                       # ApiResponse + DatabaseService (HTTP)
├── state/                          # Provider ChangeNotifiers
│   ├── profiles_state.dart         # Child profiles + active session
│   ├── settings_state.dart         # Narrator voice, speed, sensory toggles
│   └── pin_state.dart              # Caregiver PIN (flutter_secure_storage)
├── theme/                          # AppColors + AppTheme (Material 3)
├── widgets/                        # StatCard, SoftCard, SoftChip, BackPill
└── pages/
    ├── caregiver/                  # 5-tab caregiver mode
    │   ├── caregiver_shell.dart
    │   ├── caregiver_dashboard_page.dart
    │   ├── profiles_page.dart
    │   ├── add_child_dialog.dart
    │   ├── content_management_page.dart
    │   ├── upload_content_page.dart
    │   ├── insights_page.dart
    │   └── settings_page.dart      # Narration + Sensory + PIN change
    ├── child/                      # 3-tab child mode
    │   ├── child_shell.dart        # Locks back-nav behind PIN
    │   ├── child_home_page.dart    # Mood selector + Continue listening
    │   ├── story_library_page.dart # Search + category + age filters
    │   └── audio_player_page.dart  # Sensory protection + paged narration
    └── shared/
        └── guardian_pin_dialog.dart
```

### Modules implemented

The UI covers the modules from the FYP scope:

- **Profile Management** — `ProfilesState`, `add_child_dialog.dart`,
  `profiles_page.dart`, `settings_page.dart`.
- **Audio Playback Engine** — `audio_engine.dart` and the player UI in
  `audio_player_page.dart`.
- **Caregiver vs Child UI** — separate shells with a Guardian PIN gate.
- **Content Management** — list, summary, upload (calls Laravel API).
- **Accessibility / Sensory Friendly UI** — soft pastel palette, large rounded
  hit targets, Nunito font, reduced-animations toggle, "Sensory Protection
  Active" banner on the player.
- **AI Adaptive Learning** — placeholders are wired so AI hooks can be added
  to the upload flow and audio engine later.

### Autism-friendly design notes

- Soft pastel palette in [theme/app_colors.dart](frontend/lib/theme/app_colors.dart).
- Generous spacing, rounded corners (16–24px) everywhere.
- High-contrast text on white cards; no harsh shadows.
- Bottom navigation uses a colored pill behind the active icon — easy to
  scan, no animation reliance.
- Child Mode strips destructive navigation (back button, etc.) behind a
  4-digit PIN; default PIN is `1234`, changeable in Settings.

### Default PIN

`1234` — change immediately from **Settings → PIN Change**.

---

## Switching machines / emulator

| Device                      | API URL                                              |
|-----------------------------|------------------------------------------------------|
| Android emulator (artisan)  | `http://10.0.2.2:8000/api`                           |
| Android emulator (XAMPP)    | `http://10.0.2.2/audiobook_backend/backend/public/api` |
| Physical device (same Wi-Fi)| `http://<YOUR-LAN-IP>:8000/api`                      |
| iOS simulator               | `http://127.0.0.1:8000/api`                          |

Edit [frontend/lib/config/app_config.dart](frontend/lib/config/app_config.dart)
to switch.
