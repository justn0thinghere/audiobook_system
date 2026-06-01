<?php

namespace App\Http\Controllers\Api;

use App\Models\Audiobook;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class AudiobookController extends ApiController
{
    public function getAudiobookData(Request $request, string $audiobookId): JsonResponse
    {
        try {
            $validator = Validator::make(
                ['audiobook_id' => $audiobookId],
                ['audiobook_id' => 'required|string|uuid']
            );

            if ($validator->fails()) {
                return $this->errorResponse(
                    'Validation failed: ' . implode(', ', $validator->errors()->all()),
                    'VALIDATION_ERROR',
                    422
                );
            }

            $audiobook = Audiobook::where('audiobook_id', $audiobookId)->first();

            if (!$audiobook) {
                Log::error('Audiobook not found via API', ['audiobook_id' => $audiobookId]);
                return $this->errorResponse('Audiobook not found.', 'AUDIOBOOK_NOT_FOUND', 404);
            }

            return $this->successResponse('Audiobook data retrieved successfully', [
                'audiobook_id'     => $audiobook->audiobook_id,
                'title'            => $audiobook->title,
                'author'           => $audiobook->author,
                'description'      => $audiobook->description,
                'topic'            => $audiobook->topic,
                'category'         => $audiobook->category,
                'difficulty'       => $audiobook->difficulty,
                'type'             => $audiobook->type,
                'content_text'     => $audiobook->content_text,
                'audio_file'       => $this->mediaUrl($audiobook->audio_file),
                'video_file'       => $this->mediaUrl($audiobook->video_file),
                'cover_image'      => $this->mediaUrl($audiobook->cover_image),
                'duration_minutes' => $audiobook->duration_minutes,
                'language'         => $audiobook->language,
                'age_group'        => $audiobook->age_group,
                'tags'             => $audiobook->tags,
                'is_generated'     => (bool) $audiobook->is_generated,
                'is_user_uploaded' => (bool) $audiobook->is_user_uploaded,
                'status'           => $audiobook->status,
                'pages'            => $audiobook->pages->map(fn ($p) => [
                    'page_id'        => $p->page_id,
                    'page_number'    => $p->page_number,
                    'text'           => $p->text,
                    'image'          => $this->mediaUrl($p->image),
                    'audio_start_ms' => $p->audio_start_ms,
                ])->toArray(),
                'created_at'       => $audiobook->created_at
                    ? Carbon::parse($audiobook->created_at)->format('Y-m-d H:i:s')
                    : null,
                'updated_at'       => $audiobook->updated_at
                    ? Carbon::parse($audiobook->updated_at)->format('Y-m-d H:i:s')
                    : null,
            ]);
        } catch (\Throwable $e) {
            Log::error('Audiobook fetch error', [
                'error' => $e->getMessage(),
                'audiobook_id' => $audiobookId ?? 'unknown',
            ]);
            return $this->errorResponse('Internal server error', 'SERVER_ERROR', 500);
        }
    }

    /**
     * Locally-stored media (e.g. "storage/uploads/...") is made absolute;
     * values that are already full URLs (e.g. AI image links) pass through.
     */
    /**
     * Build an absolute URL for a stored relative path (e.g. "storage/uploads/..").
     *
     * Uses the INCOMING request's scheme+host instead of APP_URL, so the URL
     * is always reachable by whatever client is asking — the Android emulator
     * (which talks to the host as 10.0.2.2), a real phone on Wi-Fi, anything
     * else. With APP_URL=http://localhost the emulator would never reach the
     * static file and just_audio would silently fail, putting the player into
     * its TTS fallback.
     *
     * Already-absolute URLs (Gemini image links) pass through unchanged.
     */
    private function mediaUrl(?string $path): ?string
    {
        if ($path === null || $path === '') {
            return null;
        }
        if (\Illuminate\Support\Str::startsWith($path, ['http://', 'https://'])) {
            return $path;
        }
        $base = rtrim(request()->getSchemeAndHttpHost(), '/');
        return $base . '/' . ltrim($path, '/');
    }
}
