# Audiobook for Autism — Frontend

Flutter mobile app for the **Audiobook for Autism** system. See the [root README](../README.md) for the full project overview, modules, schema, endpoint reference, and how this app talks to the Laravel API in `../backend/`.

---

## Quickstart

```powershell
# 1. Pull dependencies
flutter pub get

# 2. Tell the app where the API lives
#    Edit lib/config/app_config.dart:
#       - Android emulator:        http://10.0.2.2:8000/api
#       - Physical phone (LAN):    http://<your-PC-LAN-IP>:8000/api

# 3. Run on a connected device
flutter devices         # confirm phone / emulator is listed
flutter run             # debug
flutter run --release   # release build, installed onto the device

# Build a stand-alone APK
flutter build apk --release
# Output: build\app\outputs\flutter-apk\app-release.apk
```

For step-by-step instructions on connecting a physical Android phone (firewall rule, LAN IP discovery, cleartext-HTTP allowance) see [../README.md → Testing on a Physical Phone](../README.md#testing-on-a-physical-phone).

---

## Layout (high level)

```
lib/
  main.dart                  App root + MultiProvider + named routes
  config/app_config.dart     API base URL (LAN IP for phone testing)
  i18n/                      AppStrings (en / ms flat maps) + BuildContext.tr
  navigation/                AppNavigationService (global key) + AppRoutes
  models/                    JSON shapes — Caregiver, ChildProfile, ChildSettings,
                             UserSettings, Audiobook, AudiobookPage, ContentItem,
                             ListeningSession, InsightsOverview, …
  services/
    api_service.dart         ApiResponse wrapper
    database_service.dart    REST client (auth, profiles, settings, content,
                             AI generation, TTS, listening history, insights)
  state/                     ChangeNotifier providers:
                             AuthState, ProfilesState, SettingsState,
                             LanguageState
  theme/                     AppColors palette + AppTheme (Nunito + Material 3)
  audio/audio_engine.dart    Thin wrapper around just_audio + audio_session
  widgets/
    soft_card.dart           Reusable rounded card
    soft_chip.dart           Reusable rounded chip
    back_pill.dart           Compact circular back button
    stat_card.dart           Dashboard stat tile (overflow-safe)
    app_snackbar.dart        Themed snackbar (info / success / warning / error)
    empty_state.dart         Themed empty-state placeholder
  pages/
    shared/                  AuthGate, LoginPage, GuardianPinDialog
    caregiver/               CaregiverShell + Dashboard, Profiles,
                             ContentManagement, UploadContent (with the
                             PageBoundariesEditor), Insights, Settings,
                             AddChildDialog
    child/                   ChildShell + Home, StoryLibrary, AudioPlayerPage
```

---

## Architecture notes

- **State** — four top-level `ChangeNotifier` providers (`AuthState`, `ProfilesState`, `SettingsState`, `LanguageState`) are bootstrapped in [main.dart](lib/main.dart) and consumed throughout via `context.watch` / `context.read`. `SettingsState` holds **per-child** settings keyed by `child_id`; entering child mode loads that child's row.
- **Routing** — every page has a constant in [navigation/app_routes.dart](lib/navigation/app_routes.dart). The audio player takes typed arguments via `onGenerateRoute`. Routes can be pushed from anywhere via [`AppNavigationService.pushNamed`](lib/navigation/app_navigation_service.dart) (uses a global navigator key, so it works from services and background callbacks too).
- **Session** — `DatabaseService` reads the token from `SharedPreferences` and adds `Authorization: Bearer <token>` to every protected request automatically.
- **Audio** — all playback goes through [`AudioEngine`](lib/audio/audio_engine.dart), a thin wrapper over `just_audio`. AI narration uses per-page WAV clips rendered server-side by Gemini TTS (cached on the backend by SHA-1 of voice|text). Pre-recorded books load the caregiver's MP3 / WAV directly; if the caregiver marked page boundaries at upload, the player auto-flips pages on each boundary, otherwise it uses a word-count heuristic.
- **i18n** — strings live in [`lib/i18n/app_strings.dart`](lib/i18n/app_strings.dart) as two flat `en` / `ms` Maps. Use `context.tr('some.key')` everywhere; `LanguageState` controls the active language and persists it via `SharedPreferences`.
- **Snackbars** — never use the raw `ScaffoldMessenger.of(context).showSnackBar` — call [`AppSnackbar.info/success/warning/error`](lib/widgets/app_snackbar.dart) instead so messages match the app's pastel theme.

---

## Where to look next

| Need | File |
|---|---|
| Project overview / modules | [../README.md](../README.md) |
| API endpoint reference | [../README.md → REST API Reference](../README.md#rest-api-reference) |
| API base URL | [lib/config/app_config.dart](lib/config/app_config.dart) |
| Theme & palette | [lib/theme/app_colors.dart](lib/theme/app_colors.dart), [lib/theme/app_theme.dart](lib/theme/app_theme.dart) |
| Route table | [lib/navigation/app_routes.dart](lib/navigation/app_routes.dart) |
| Audio player + read-along + auto-flip | [lib/pages/child/audio_player_page.dart](lib/pages/child/audio_player_page.dart) |
| Upload page + page-boundary editor | [lib/pages/caregiver/upload_content_page.dart](lib/pages/caregiver/upload_content_page.dart) |
| Per-child Settings page | [lib/pages/caregiver/settings_page.dart](lib/pages/caregiver/settings_page.dart) |
| Insights page (chart + per-child) | [lib/pages/caregiver/insights_page.dart](lib/pages/caregiver/insights_page.dart) |
| i18n strings (en / ms) | [lib/i18n/app_strings.dart](lib/i18n/app_strings.dart) |
