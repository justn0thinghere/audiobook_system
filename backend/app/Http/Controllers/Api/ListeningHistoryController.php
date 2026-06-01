<?php

namespace App\Http\Controllers\Api;

use App\Models\ChildProfile;
use App\Models\ListeningHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ListeningHistoryController extends ApiController
{
    public function record(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'child_id'              => 'required|string|uuid',
            'audiobook_id'          => 'required|string|uuid',
            'duration_seconds'      => 'nullable|integer|min:0',
            'last_position_seconds' => 'nullable|integer|min:0',
            'mood'                  => 'nullable|in:happy,calm,curious,sleepy',
            'completed'             => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        $caregiver = $request->get('auth_caregiver');
        $profile = ChildProfile::where('child_id', $request->input('child_id'))
            ->where('caregiver_id', $caregiver->caregiver_id)
            ->first();
        if (!$profile) {
            return $this->errorResponse('Child profile not found', 'NOT_FOUND', 404);
        }

        $history = ListeningHistory::create($validator->validated());

        // Increment the rolling per-profile counter.
        if ($request->filled('duration_seconds')) {
            $profile->increment(
                'listening_minutes',
                (int) round(((int) $request->input('duration_seconds')) / 60)
            );
        }

        return $this->successResponse('Listening session recorded', [
            'history_id'            => $history->history_id,
            'child_id'              => $history->child_id,
            'audiobook_id'          => $history->audiobook_id,
            'duration_seconds'      => $history->duration_seconds,
            'last_position_seconds' => $history->last_position_seconds,
            'mood'                  => $history->mood,
            'completed'             => (bool) $history->completed,
        ]);
    }

    public function forProfile(Request $request, string $childId): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        $profile = ChildProfile::where('child_id', $childId)
            ->where('caregiver_id', $caregiver->caregiver_id)
            ->first();
        if (!$profile) {
            return $this->errorResponse('Child profile not found', 'NOT_FOUND', 404);
        }

        $history = $profile->listeningHistory()
            ->orderByDesc('created_at')
            ->limit(50)
            ->get()
            ->map(fn ($h) => [
                'history_id'            => $h->history_id,
                'audiobook_id'          => $h->audiobook_id,
                'duration_seconds'      => $h->duration_seconds,
                'last_position_seconds' => $h->last_position_seconds,
                'mood'                  => $h->mood,
                'completed'             => (bool) $h->completed,
                'created_at'            => $h->created_at?->format('Y-m-d H:i:s'),
            ]);

        return $this->successResponse('OK', $history);
    }
}
