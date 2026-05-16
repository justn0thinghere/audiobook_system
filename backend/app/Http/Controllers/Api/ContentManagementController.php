<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Audiobook;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class ContentManagementController extends Controller
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
            'type'         => 'nullable|in:Audio,Text',
            'tags'         => 'nullable|string',
            'content_text' => 'nullable|string',
            'description'  => 'nullable|string',
            'age_group'    => 'nullable|string|max:50',
            'is_generated' => 'nullable|boolean',
            'source_file'  => 'nullable|file|mimes:pdf,txt,mp3,wav|max:10240',
            'audio_file'   => 'nullable|file|mimes:mp3,wav|max:20480',
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
            $coverImagePath = null;

            if ($request->hasFile('source_file')) {
                $sourceFilePath = 'storage/' . $request->file('source_file')->store('uploads/content', 'public');
            }
            if ($request->hasFile('audio_file')) {
                $audioFilePath = 'storage/' . $request->file('audio_file')->store('uploads/audio', 'public');
            }
            if ($request->hasFile('cover_image')) {
                $coverImagePath = 'storage/' . $request->file('cover_image')->store('uploads/covers', 'public');
            }

            $isGenerated = $request->boolean('is_generated');
            $type = $request->input('type', $audioFilePath ? 'Audio' : 'Text');
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
                'source_file'      => $sourceFilePath,
                'audio_file'       => $audioFilePath,
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
            'audio_file'       => $item->audio_file ? url($item->audio_file) : null,
            'source_file'      => $item->source_file ? url($item->source_file) : null,
            'cover_image'      => $item->cover_image ? url($item->cover_image) : null,
            'duration_minutes' => $item->duration_minutes,
            'language'         => $item->language,
            'age_group'        => $item->age_group,
            'tags'             => $item->tags,
            'is_generated'     => (bool) $item->is_generated,
            'is_user_uploaded' => (bool) $item->is_user_uploaded,
            'status'           => $item->status,
            'created_at'       => $item->created_at ? Carbon::parse($item->created_at)->format('Y-m-d H:i:s') : null,
            'updated_at'       => $item->updated_at ? Carbon::parse($item->updated_at)->format('Y-m-d H:i:s') : null,
        ];
    }
}
