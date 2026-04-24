<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Audiobook;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class ContentManagementController extends Controller
{
    private function errorResponse(string $message, string $errorCode = 'ERROR', int $statusCode = 400): JsonResponse
    {
        return response()->json([
            'status' => 'ERROR',
            'message' => $message,
            'error_code' => $errorCode,
            'timestamp' => now('Asia/Kuala_Lumpur')->format('Y-m-d H:i:s')
        ], $statusCode);
    }

    private function successResponse(string $message, array $data = null): JsonResponse
    {
        $response = [
            'status' => 'SUCCESS',
            'message' => $message,
            'timestamp' => now('Asia/Kuala_Lumpur')->format('Y-m-d H:i:s')
        ];

        if ($data !== null) {
            $response['data'] = $data;
        }

        return response()->json($response);
    }

    public function getContentSummary(Request $request): JsonResponse
    {
        try {
            $totalItems = Audiobook::count();
            $audioFiles = Audiobook::where('type', 'Audio')->count();
            $textFiles = Audiobook::where('type', 'Text')->count();
            $aiGenerated = Audiobook::where('is_generated', 1)->count();

            $summary = [
                'total_items' => $totalItems,
                'audio_files' => $audioFiles,
                'text_files' => $textFiles,
                'ai_generated' => $aiGenerated,
            ];

            Log::info('Content summary retrieved', [
                'partner_id' => $request->PID ?? null
            ]);

            return $this->successResponse('Content summary retrieved successfully', $summary);
        } catch (\Exception $e) {
            Log::error('Error retrieving content summary', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse('Internal server error', 'SERVER_ERROR', 500);
        }
    }

    public function getContentList(Request $request): JsonResponse
    {
        try {

            $contents = Audiobook::orderBy('created_at', 'desc')->get();

            $contentList = $contents->map(function ($item) {
                return [
                    'content_id' => $item->id,
                    'title' => $item->title,
                    'author' => $item->author,
                    'description' => $item->description,
                    'topic' => $item->topic,
                    'category' => $item->category,
                    'difficulty' => $item->difficulty,
                    'type' => $item->type,
                    'content_text' => $item->content_text,
                    'audio_file' => $item->audio_file ? url($item->audio_file) : null,
                    'source_file' => $item->source_file ? url($item->source_file) : null,
                    'cover_image' => $item->cover_image ? url($item->cover_image) : null,
                    'duration_minutes' => $item->duration_minutes,
                    'language' => $item->language,
                    'age_group' => $item->age_group,
                    'tags' => $item->tags,
                    'is_generated' => (bool) $item->is_generated,
                    'is_user_uploaded' => (bool) $item->is_user_uploaded,
                    'status' => $item->status,
                    'created_at' => $item->created_at
                        ? Carbon::parse($item->created_at)->format('Y-m-d')
                        : null,
                    'updated_at' => $item->updated_at
                        ? Carbon::parse($item->updated_at)->format('Y-m-d H:i:s')
                        : null,
                ];
            })->toArray();

            return $this->successResponse('Content list retrieved successfully', [
                'items' => $contentList
            ]);
        } catch (\Exception $e) {
            Log::error('Error retrieving content list', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse('Internal server error', 'SERVER_ERROR', 500);
        }
    }

    public function createContent(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'title' => 'required|string|max:255',
                'topic' => 'nullable|string|max:100',
                'difficulty' => 'required|in:Easy,Medium,Hard',
                'type' => 'required|in:Audio,Text',
                'tags' => 'nullable|string',
                'content_text' => 'nullable|string',
                'description' => 'nullable|string',
                'is_generated' => 'nullable|boolean',
                'source_file' => 'nullable|file|mimes:pdf,txt,mp3,wav|max:10240',
                'audio_file' => 'nullable|file|mimes:mp3,wav|max:20480',
                'cover_image' => 'nullable|image|mimes:jpg,jpeg,png|max:5120',
            ]);

            if ($validator->fails()) {
                return $this->errorResponse(
                    'Validation failed: ' . implode(', ', $validator->errors()->all()),
                    'VALIDATION_ERROR',
                    422
                );
            }

            $sourceFilePath = null;
            $audioFilePath = null;
            $coverImagePath = null;

            if ($request->hasFile('source_file')) {
                $sourceFilePath = $request->file('source_file')->store('uploads/content', 'public');
                $sourceFilePath = 'storage/' . $sourceFilePath;
            }

            if ($request->hasFile('audio_file')) {
                $audioFilePath = $request->file('audio_file')->store('uploads/audio', 'public');
                $audioFilePath = 'storage/' . $audioFilePath;
            }

            if ($request->hasFile('cover_image')) {
                $coverImagePath = $request->file('cover_image')->store('uploads/covers', 'public');
                $coverImagePath = 'storage/' . $coverImagePath;
            }

            $content = Audiobook::create([
                'title' => $request->title,
                'topic' => $request->topic,
                'difficulty' => $request->difficulty,
                'type' => $request->type,
                'tags' => $request->tags,
                'description' => $request->description,
                'content_text' => $request->content_text,
                'source_file' => $sourceFilePath,
                'audio_file' => $audioFilePath,
                'cover_image' => $coverImagePath,
                'is_generated' => $request->boolean('is_generated'),
                'is_user_uploaded' => 1,
                'status' => $request->boolean('is_generated') ? 'Processing' : 'Available',
            ]);

            Log::info('Content created successfully', [
                'content_id' => $content->id,
                'title' => $content->title,
            ]);

            return $this->successResponse('Content uploaded successfully', [
                'content_id' => $content->id,
                'title' => $content->title,
            ]);
        } catch (\Exception $e) {
            Log::error('Error creating content', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse('Internal server error', 'SERVER_ERROR', 500);
        }
    }
}