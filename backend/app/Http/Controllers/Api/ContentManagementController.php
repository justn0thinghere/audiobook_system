<?php

namespace App\Http\Controllers\Api;

use App\Jobs\GenerateAudiobookImages;
use App\Models\Audiobook;
use App\Services\GeminiService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class ContentManagementController extends ApiController
{
    public function getContentSummary(Request $request): JsonResponse
    {
        try {
            return $this->successResponse('Content summary retrieved successfully', [
                'total_items'  => Audiobook::count(),
                'audio_files'  => Audiobook::where('type', 'Audio')->count(),
                'text_files'   => Audiobook::where('type', 'Text')->count(),
                'ai_generated' => Audiobook::where('is_generated', 1)->count(),
            ]);
        } catch (\Throwable $e) {
            Log::error('Content summary error', ['error' => $e->getMessage()]);
            return $this->errorResponse('Internal server error', 'SERVER_ERROR', 500);
        }
    }

    public function getContentList(Request $request): JsonResponse
    {
        try {
            $query = Audiobook::query()->orderByDesc('created_at');

            if ($request->filled('filter_type')) {
                $filter = strtolower($request->input('filter_type'));
                if ($filter === 'audio') {
                    $query->where('type', 'Audio')->where('is_generated', 0);
                } elseif ($filter === 'text') {
                    $query->where('type', 'Text')->where('is_generated', 0);
                } elseif ($filter === 'ai') {
                    $query->where('is_generated', 1);
                }
            }

            if ($request->filled('search')) {
                $search = '%' . $request->input('search') . '%';
                $query->where(function ($q) use ($search) {
                    $q->where('title', 'like', $search)
                      ->orWhere('author', 'like', $search)
                      ->orWhere('topic', 'like', $search)
                      ->orWhere('category', 'like', $search)
                      ->orWhere('tags', 'like', $search);
                });
            }

            if ($request->filled('category')) {
                $query->where('category', $request->input('category'));
            }

            if ($request->filled('age_group')) {
                $query->where('age_group', $request->input('age_group'));
            }

            // Language filter — books default to 'en' but the caregiver can
            // generate Malay stories now, so let the library narrow to one.
            if ($request->filled('language')) {
                $query->where('language', strtolower($request->input('language')));
            }

            $items = $query->get()->map(fn ($item) => $this->serialize($item))->toArray();

            return $this->successResponse('Content list retrieved successfully', [
                'items' => $items,
            ]);
        } catch (\Throwable $e) {
            Log::error('Content list error', ['error' => $e->getMessage()]);
            return $this->errorResponse('Internal server error', 'SERVER_ERROR', 500);
        }
    }

    public function createContent(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'title'        => 'required|string|max:255',
            'topic'        => 'nullable|string|max:100',
            'category'     => 'nullable|string|max:100',
            'difficulty'   => 'nullable|in:easy,medium,hard,Easy,Medium,Hard',
            'type'         => 'nullable|in:Audio,Text,Video',
            'tags'         => 'nullable|string',
            'content_text' => 'nullable|string',
            'description'  => 'nullable|string',
            'age_group'    => 'nullable|string|max:50',
            'is_generated' => 'nullable|boolean',
            'language'     => 'nullable|in:en,ms',
            'source_file'  => 'nullable|file|mimes:pdf,txt,mp3,wav|max:10240',
            // Use mimetypes (content sniffing) rather than mimes (filename
            // extension) and cover the common variants Android / iOS pickers
            // actually return for MP3, WAV, M4A, AAC and Ogg files — Laravel's
            // strict "mp3,wav" map sometimes rejects valid MP3s that come
            // through as audio/mpeg or audio/mp4 on real devices.
            'audio_file'   => 'nullable|file|max:20480|mimetypes:audio/mpeg,audio/mp3,audio/mpga,audio/wav,audio/x-wav,audio/wave,audio/vnd.wave,audio/x-pn-wav,audio/mp4,audio/x-m4a,audio/aac,audio/x-aac,audio/ogg,audio/vorbis,audio/flac,audio/webm',
            'video_file'   => 'nullable|file|mimes:mp4,mov,webm|max:51200',
            'cover_image'  => 'nullable|image|mimes:jpg,jpeg,png|max:5120',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        try {
            $sourceFilePath = null;
            $audioFilePath  = null;
            $videoFilePath  = null;
            $coverImagePath = null;

            if ($request->hasFile('source_file')) {
                $sourceFilePath = 'storage/' . $request->file('source_file')->store('uploads/content', 'public');
            }
            if ($request->hasFile('audio_file')) {
                $audioFilePath = 'storage/' . $request->file('audio_file')->store('uploads/audio', 'public');
            }
            if ($request->hasFile('video_file')) {
                $videoFilePath = 'storage/' . $request->file('video_file')->store('uploads/video', 'public');
            }
            if ($request->hasFile('cover_image')) {
                $coverImagePath = 'storage/' . $request->file('cover_image')->store('uploads/covers', 'public');
            }

            $isGenerated = $request->boolean('is_generated');
            $type = $request->input('type')
                ?? ($videoFilePath ? 'Video' : ($audioFilePath ? 'Audio' : 'Text'));
            $difficulty = strtolower((string) $request->input('difficulty', 'easy'));

            $content = Audiobook::create([
                'title'            => $request->input('title'),
                'topic'            => $request->input('topic'),
                'category'         => $request->input('category'),
                'difficulty'       => $difficulty,
                'type'             => $type,
                'tags'             => $request->input('tags'),
                'description'     => $request->input('description'),
                'content_text'     => $request->input('content_text'),
                'age_group'        => $request->input('age_group'),
                'language'         => $request->input('language') ?: 'en',
                'source_file'      => $sourceFilePath,
                'audio_file'       => $audioFilePath,
                'video_file'       => $videoFilePath,
                'cover_image'      => $coverImagePath,
                'is_generated'     => $isGenerated,
                'is_user_uploaded' => true,
                'status'           => $isGenerated ? 'processing' : 'available',
            ]);

            return $this->successResponse('Content uploaded successfully', $this->serialize($content));
        } catch (\Throwable $e) {
            Log::error('Create content error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return $this->errorResponse('Internal server error', 'SERVER_ERROR', 500);
        }
    }

    /**
     * Generate a story (and optional cover image) with Gemini AI and save it
     * as a new audiobook. Used by the caregiver "Generate with AI" flow (UC-6).
     */
    public function generateContent(Request $request, GeminiService $gemini): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'topic'          => 'required|string|max:255',
            'age_group'      => 'nullable|string|max:50',
            'category'       => 'nullable|string|max:100',
            'difficulty'     => 'nullable|in:easy,medium,hard,Easy,Medium,Hard',
            'tags'           => 'nullable|string',
            'source_text'    => 'nullable|string',
            'generate_image' => 'nullable|boolean',
            'page_count'     => 'nullable|integer|min:1|max:20',
            'language'       => 'nullable|in:en,ms',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        if (!$gemini->isConfigured()) {
            return $this->errorResponse(
                'AI is not configured. Add GEMINI_API_KEY to the backend .env file.',
                'AI_NOT_CONFIGURED',
                503
            );
        }

        try {
            $story = $gemini->generateStory(
                $request->input('topic'),
                $request->input('age_group'),
                $request->input('source_text'),
                $request->filled('page_count') ? (int) $request->input('page_count') : null,
                $request->input('language'),
            );

            $generateImages = $request->boolean('generate_image');

            // The story text is ready instantly. Each page image takes ~12s, so
            // we save the book as "processing", then draw every page via the
            // GenerateAudiobookImages job and flip it to "available".
            //
            // With QUEUE_CONNECTION=sync (the default here) the job runs inline
            // during this request — no separate worker needed — so the book is
            // already finished when we respond. With QUEUE_CONNECTION=database it
            // runs in the background (needs `php artisan queue:work`) and the app
            // shows a pending state until the job finishes.
            $content = Audiobook::create([
                // Keep the caregiver's typed text as the title — don't rename it
                // to the AI's invented title.
                'title'            => trim((string) $request->input('topic')),
                'topic'            => $request->input('topic'),
                'category'         => $request->input('category'),
                'difficulty'       => strtolower((string) $request->input('difficulty', 'easy')),
                'type'             => 'Text',
                'tags'             => $request->input('tags'),
                'content_text'     => $story['content'],
                'age_group'        => $request->input('age_group'),
                'language'         => $request->input('language') ?: 'en',
                'is_generated'     => true,
                'is_user_uploaded' => true,
                'status'           => $generateImages ? 'processing' : 'available',
            ]);

            foreach ($story['pages'] as $i => $page) {
                $content->pages()->create([
                    'page_number'  => $i + 1,
                    'text'         => $page['text'],
                    'image_prompt' => $page['image_prompt'],
                    'image'        => null,
                ]);
            }

            if ($generateImages) {
                @set_time_limit(0); // inline image generation can take ~1 minute
                @ignore_user_abort(true); // finish even if the client navigates away
                GenerateAudiobookImages::dispatch($content->audiobook_id);
                $content->refresh(); // 'available' now if the job ran inline (sync)
            }

            $ready = $content->status === 'available';
            $message = !$generateImages
                ? 'AI story generated.'
                : ($ready
                    ? 'Your storybook is ready, with a picture on every page!'
                    : 'Your storybook is being created — it will appear in the library when ready.');

            return $this->successResponse($message, $this->serialize($content->load('pages')));
        } catch (\Throwable $e) {
            Log::error('AI generate content error', ['error' => $e->getMessage()]);
            return $this->errorResponse(
                'AI generation failed: ' . $e->getMessage(),
                'AI_FAILED',
                502
            );
        }
    }

    /**
     * Add a single page (text + optional image) to an existing audiobook.
     * Multipart request: text, image (file), page_number.
     */
    public function addPage(Request $request, string $audiobookId): JsonResponse
    {
        $book = Audiobook::where('audiobook_id', $audiobookId)->first();
        if (!$book) {
            return $this->errorResponse('Audiobook not found', 'NOT_FOUND', 404);
        }

        $validator = Validator::make($request->all(), [
            'text'           => 'nullable|string',
            'page_number'    => 'nullable|integer|min:1',
            'image'          => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
            // Caregiver-supplied page boundary on the whole-book recording.
            'audio_start_ms' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        try {
            $imagePath = null;
            if ($request->hasFile('image')) {
                $imagePath = 'storage/' . $request->file('image')->store('uploads/pages', 'public');
            }

            $pageNumber = (int) $request->input('page_number', $book->pages()->count() + 1);

            $page = $book->pages()->create([
                'page_number'    => $pageNumber,
                'text'           => $request->input('text'),
                'image'          => $imagePath,
                'audio_start_ms' => $request->filled('audio_start_ms')
                    ? (int) $request->input('audio_start_ms')
                    : null,
            ]);

            // First page's image doubles as the cover when none is set.
            if ($imagePath && empty($book->cover_image) && $pageNumber === 1) {
                $book->cover_image = $imagePath;
                $book->save();
            }

            return $this->successResponse('Page added', [
                'page_id'     => $page->page_id,
                'page_number' => $page->page_number,
                'text'        => $page->text,
                'image'       => $this->mediaUrl($page->image),
            ]);
        } catch (\Throwable $e) {
            Log::error('Add page error', ['error' => $e->getMessage()]);
            return $this->errorResponse('Could not add page', 'SERVER_ERROR', 500);
        }
    }

    /**
     * Turn a stored media reference into a usable URL. Locally-stored files
     * (e.g. "storage/uploads/...") are made absolute; values that are already
     * full URLs (e.g. AI image links) are returned unchanged.
     */
    private function mediaUrl(?string $path): ?string
    {
        if ($path === null || $path === '') {
            return null;
        }
        return \Illuminate\Support\Str::startsWith($path, ['http://', 'https://'])
            ? $path
            : url($path);
    }

    private function serializePages(Audiobook $item): array
    {
        return $item->pages->map(fn ($p) => [
            'page_id'     => $p->page_id,
            'page_number' => $p->page_number,
            'text'        => $p->text,
            'image'       => $this->mediaUrl($p->image),
        ])->toArray();
    }

    private function serialize(Audiobook $item): array
    {
        return [
            'audiobook_id'     => $item->audiobook_id,
            'title'            => $item->title,
            'author'           => $item->author,
            'description'      => $item->description,
            'topic'            => $item->topic,
            'category'         => $item->category,
            'difficulty'       => $item->difficulty,
            'type'             => $item->type,
            'content_text'     => $item->content_text,
            'audio_file'       => $this->mediaUrl($item->audio_file),
            'video_file'       => $this->mediaUrl($item->video_file),
            'source_file'      => $this->mediaUrl($item->source_file),
            'cover_image'      => $this->mediaUrl($item->cover_image),
            'duration_minutes' => $item->duration_minutes,
            'language'         => $item->language,
            'age_group'        => $item->age_group,
            'tags'             => $item->tags,
            'is_generated'     => (bool) $item->is_generated,
            'is_user_uploaded' => (bool) $item->is_user_uploaded,
            'status'           => $item->status,
            'pages'            => $this->serializePages($item),
            'created_at'       => $item->created_at ? Carbon::parse($item->created_at)->format('Y-m-d H:i:s') : null,
            'updated_at'       => $item->updated_at ? Carbon::parse($item->updated_at)->format('Y-m-d H:i:s') : null,
        ];
    }
}
