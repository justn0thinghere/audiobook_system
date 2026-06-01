# Audiobook for Autism — Backend

Laravel 11 REST API for the **Audiobook for Autism** system. See the [root README](../README.md) for the full project overview, modules, schema, endpoint reference, and how everything fits together with the Flutter app in `../frontend/`.

---

## Quickstart

```powershell
# 1. PHP dependencies
composer install

# 2. Env + app key
copy .env.example .env
php artisan key:generate

# 3. Create the database in phpMyAdmin
#    Name: autism_audiobook
#    Then set DB_DATABASE / DB_USERNAME / DB_PASSWORD in .env
#    Also set GEMINI_API_KEY=<your_key> for AI text / image / TTS

# 4. Create the tables (drops + rebuilds all UUID tables)
php artisan migrate:fresh

# 5. Publish the storage symlink so uploaded / generated media is served
php artisan storage:link

# 6. Serve to your LAN so a phone can reach the API
php artisan serve --host=0.0.0.0 --port=8000
```

Health check: `POST http://<host>:8000/api/test`.

`APP_URL` does **not** need to point at a specific host — controllers build media URLs from the request's host, so the same backend serves correct URLs to emulator (`10.0.2.2:8000`) and to real devices on Wi-Fi.

---

## Layout (high level)

```
app/
  Models/               Caregiver, ChildProfile, CaregiverSettings,
                        ChildSettings, Audiobook, AudiobookPage,
                        ListeningHistory   (all UUID-keyed)
  Services/
    GeminiService.php   Gemini API client — text (gemini-2.5-flash),
                        image (gemini-2.5-flash-image), TTS (gemini-2.5-
                        flash-preview-tts). Caches TTS by SHA-1(voice|text).
  Jobs/
    GenerateAudiobookImages.php   Background image generation for AI books.
  Http/
    Controllers/Api/    ApiController (base) + Auth, ChildProfile, Settings,
                        Audiobook, ContentManagement, ListeningHistory,
                        Insights, Tts
    Middleware/         SessionAuthMiddleware  (Bearer-token gate)
database/migrations/    UUID tables — caregivers, child_profiles,
                        caregiver_settings, child_settings, audiobooks,
                        audiobook_pages, listening_history (+ schema
                        evolution migrations for image_prompt,
                        audio_start_ms, widened image columns, etc.)
storage/app/public/     uploads/covers, uploads/audio, uploads/pages, tts
routes/api.php          Public /auth/* + protected `session.auth` group
config/auth.php         User provider points to App\Models\Caregiver
```

---

## Conventions

- **All endpoints are `POST`** (multipart only for `/content/create` and `/content/{id}/pages`).
- **All IDs are 36-char UUIDs**, auto-generated via Laravel's `HasUuids` trait.
- **Session token** is issued at `/auth/login` and `/auth/register`, sent back as `Authorization: Bearer <token>` on every protected request. Sliding 24-hour expiry — see [`SessionAuthMiddleware`](app/Http/Middleware/SessionAuthMiddleware.php).
- **Response shape** is always `{ status, message, data?, error_code?, timestamp }`. Helpers `successResponse()` / `errorResponse()` on the base [`ApiController`](app/Http/Controllers/Api/ApiController.php) produce this.
- **Media URLs are request-aware** — every controller has a `mediaUrl()` helper that builds absolute URLs from `request()->getSchemeAndHttpHost()`, so emulator clients (10.0.2.2) and real-device clients (LAN IP) each get a reachable URL without `.env` changes. Already-absolute URLs (Gemini image links) pass through unchanged.
- **Per-child settings** live in their own `child_settings` table keyed by `child_id`; the historical `caregiver_settings` table is account-level only.

---

## Gemini AI

`App\Services\GeminiService` is the single entry point for all three Gemini APIs:

| Capability | Model | Notes |
|---|---|---|
| Story text | `gemini-2.5-flash` | Returns structured JSON (pages + per-page `image_prompt`). |
| Page illustrations | `gemini-2.5-flash-image` | **Needs a billing-enabled key** (free tier returns 0 quota). 1024² PNG output is downscaled to ≤ 768² JPEG on save via `gd`. |
| Narration (TTS) | `gemini-2.5-flash-preview-tts` | Per-page WAV cached by SHA-1 of `(voice|text)` under `storage/app/public/tts/`. |

Set the key in `.env`:

```dotenv
GEMINI_API_KEY=...
GEMINI_TEXT_MODEL=gemini-2.5-flash
GEMINI_IMAGE_MODEL=gemini-2.5-flash-image
```

Image generation is dispatched via [`App\Jobs\GenerateAudiobookImages`](app/Jobs/GenerateAudiobookImages.php) so the create-audiobook request returns immediately; pages show a *Generating…* state in the app while the job runs.

---

## Reset the database during development

```powershell
php artisan migrate:fresh        # drops everything and re-runs migrations
```

> If you already have data you want to preserve, use plain `php artisan migrate` instead — it only applies the migrations not yet recorded in the `migrations` table.

---

## Where to look next

| Need | File |
|---|---|
| Full API endpoint table | [../README.md → REST API Reference](../README.md#rest-api-reference) |
| Database schema | [../README.md → Database Schema](../README.md#database-schema) |
| Migration files | [database/migrations/](database/migrations/) |
| Auth middleware | [app/Http/Middleware/SessionAuthMiddleware.php](app/Http/Middleware/SessionAuthMiddleware.php) |
| Gemini API client | [app/Services/GeminiService.php](app/Services/GeminiService.php) |
| Background image-gen job | [app/Jobs/GenerateAudiobookImages.php](app/Jobs/GenerateAudiobookImages.php) |
| Insights endpoint | [app/Http/Controllers/Api/InsightsController.php](app/Http/Controllers/Api/InsightsController.php) |
| TTS endpoint | [app/Http/Controllers/Api/TtsController.php](app/Http/Controllers/Api/TtsController.php) |
| Caregiver model (UUID setup) | [app/Models/Caregiver.php](app/Models/Caregiver.php) |
