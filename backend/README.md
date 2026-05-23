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

# 4. Create the tables (drops + rebuilds all five UUID tables)
php artisan migrate:fresh

# 5. Serve to your LAN so a phone can reach the API
php artisan serve --host=0.0.0.0 --port=8000
```

Health check: `POST http://<host>:8000/api/test`.

---

## Layout (high level)

```
app/
  Models/               Caregiver, ChildProfile, CaregiverSettings,
                        Audiobook, ListeningHistory  (all UUID-keyed)
  Http/
    Controllers/Api/    AuthController, ChildProfileController, SettingsController,
                        AudiobookController, ContentManagementController,
                        ListeningHistoryController
    Middleware/         SessionAuthMiddleware  (Bearer-token gate)
database/migrations/    5 UUID-based tables (caregivers, child_profiles,
                        caregiver_settings, listening_history, audiobooks)
routes/api.php          Public /auth/* + protected session.auth group
config/auth.php         User provider points to App\Models\Caregiver
```

---

## Conventions

- **All endpoints are `POST`** (multipart only for `/content/create`).
- **All IDs are 36-char UUIDs**, auto-generated via Laravel's `HasUuids` trait.
- **Session token** is issued at `/auth/login` and `/auth/register`, sent back as `Authorization: Bearer <token>` on every protected request. Sliding 24-hour expiry — see [`SessionAuthMiddleware`](app/Http/Middleware/SessionAuthMiddleware.php).
- **Response shape** is always `{ status, message, data?, error_code?, timestamp }`. Helpers `successResponse()` / `errorResponse()` on the base [`Controller`](app/Http/Controllers/Controller.php) produce this.

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
| Caregiver model (UUID setup) | [app/Models/Caregiver.php](app/Models/Caregiver.php) |
