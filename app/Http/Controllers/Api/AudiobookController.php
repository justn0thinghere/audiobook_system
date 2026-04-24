<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Models\Audiobook;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class AudiobookController extends Controller
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

    public function getAudiobookData(Request $request, int $id): JsonResponse
    {
        try {
            $validator = Validator::make(
                ['id' => $id],
                ['id' => 'required|integer|min:1']
            );

            if ($validator->fails()) {
                return $this->errorResponse(
                    'Validation failed: ' . implode(', ', $validator->errors()->all()),
                    'VALIDATION_ERROR',
                    422
                );
            }

            $audiobook = Audiobook::find($id);

            if (!$audiobook) {
                Log::error('Audiobook not found via API', [
                    'audiobook_id' => $id,
                ]);

                return $this->errorResponse(
                    'Audiobook not found.',
                    'AUDIOBOOK_NOT_FOUND',
                    404
                );
            }

            $audiobookData = [
                'audiobook_id' => $audiobook->id,
                'title' => $audiobook->title,
                'author' => $audiobook->author,
                'description' => $audiobook->description,
                'category' => $audiobook->category,
                'difficulty' => $audiobook->difficulty,
                'content_text' => $audiobook->content_text,
                'audio_file' => $audiobook->audio_file,
                'cover_image' => $audiobook->cover_image,
                'duration_minutes' => $audiobook->duration_minutes,
                'language' => $audiobook->language,
                'age_group' => $audiobook->age_group,
                'is_generated' => $audiobook->is_generated,
                'status' => $audiobook->status,
                'created_at' => $audiobook->created_at
                    ? Carbon::parse($audiobook->created_at)->format('Y-m-d H:i:s')
                    : null,
                'updated_at' => $audiobook->updated_at
                    ? Carbon::parse($audiobook->updated_at)->format('Y-m-d H:i:s')
                    : null,
            ];

            Log::info('Audiobook data retrieved via API', [
                'audiobook_id' => $audiobook->id,
                'title' => $audiobook->title
            ]);

            return $this->successResponse('Audiobook data retrieved successfully', $audiobookData);
        } catch (\Exception $e) {
            Log::error('Error retrieving audiobook data via API', [
                'error' => $e->getMessage(),
                'audiobook_id' => $id ?? 'unknown',
                'partner_id' => $request->PID ?? 'unknown',
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse('Internal server error', 'SERVER_ERROR', 500);
        }
    }
}