<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Audiobook;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class AudiobookController extends Controller
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
                'audio_file'       => $audiobook->audio_file ? asset($audiobook->audio_file) : null,
                'video_file'       => $audiobook->video_file ? asset($audiobook->video_file) : null,
                'cover_image'      => $audiobook->cover_image ? asset($audiobook->cover_image) : null,
                'duration_minutes' => $audiobook->duration_minutes,
                'language'         => $audiobook->language,
                'age_group'        => $audiobook->age_group,
                'tags'             => $audiobook->tags,
                'is_generated'     => (bool) $audiobook->is_generated,
                'is_user_uploaded' => (bool) $audiobook->is_user_uploaded,
                'status'           => $audiobook->status,
                'pages'            => $audiobook->pages->map(fn ($p) => [
                    'page_id'     => $p->page_id,
                    'page_number' => $p->page_number,
                    'text'        => $p->text,
                    'image'       => $p->image ? asset($p->image) : null,
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
}
