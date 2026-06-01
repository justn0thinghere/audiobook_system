<?php

namespace App\Http\Controllers\Api;

use App\Models\ChildProfile;
use App\Models\ChildSettings;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ChildProfileController extends ApiController
{
    public function index(Request $request): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        $profiles = $caregiver->childProfiles()->orderBy('created_at')->get()
            ->map(fn ($p) => $this->serialize($p));
        return $this->successResponse('OK', $profiles);
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name'           => 'required|string|max:50',
            'age'            => 'required|integer|min:1|max:18',
            'avatar_emoji'   => 'nullable|string|max:8',
            'avatar_color'   => 'nullable|string|max:9',
            'favorite_genre' => 'nullable|string|max:50',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        $caregiver = $request->get('auth_caregiver');
        $profile = $caregiver->childProfiles()->create([
            'name'           => $request->input('name'),
            'age'            => $request->input('age'),
            'avatar_emoji'   => $request->input('avatar_emoji', '🌟'),
            'avatar_color'   => $request->input('avatar_color', '#F5D5DD'),
            'favorite_genre' => $request->input('favorite_genre'),
        ]);

        return $this->successResponse('Profile created', $this->serialize($profile));
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        $profile = $caregiver->childProfiles()->where('child_id', $id)->first();
        if (!$profile) {
            return $this->errorResponse('Profile not found', 'NOT_FOUND', 404);
        }

        $validator = Validator::make($request->all(), [
            'name'              => 'sometimes|string|max:50',
            'age'               => 'sometimes|integer|min:1|max:18',
            'avatar_emoji'      => 'sometimes|string|max:8',
            'avatar_color'      => 'sometimes|string|max:9',
            'favorite_genre'    => 'sometimes|nullable|string|max:50',
            'listening_minutes' => 'sometimes|integer|min:0',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        $profile->fill($validator->validated())->save();
        return $this->successResponse('Profile updated', $this->serialize($profile));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        $profile = $caregiver->childProfiles()->where('child_id', $id)->first();
        if (!$profile) {
            return $this->errorResponse('Profile not found', 'NOT_FOUND', 404);
        }
        $profile->delete();
        return $this->successResponse('Profile deleted');
    }

    /**
     * Per-child narration & sensory/playback settings. Creates a default row
     * the first time it's requested.
     */
    public function showSettings(Request $request, string $id): JsonResponse
    {
        $profile = $this->ownedProfile($request, $id);
        if (!$profile) {
            return $this->errorResponse('Profile not found', 'NOT_FOUND', 404);
        }
        $settings = $profile->childSettings
            ?? ChildSettings::create(['child_id' => $profile->child_id]);
        return $this->successResponse('OK', $this->serializeSettings($settings));
    }

    public function updateSettings(Request $request, string $id): JsonResponse
    {
        $profile = $this->ownedProfile($request, $id);
        if (!$profile) {
            return $this->errorResponse('Profile not found', 'NOT_FOUND', 404);
        }

        $validator = Validator::make($request->all(), [
            'narrator_voice'     => 'sometimes|in:' . implode(',', ChildSettings::ALLOWED_VOICES),
            'reading_speed'      => 'sometimes|numeric|min:0.5|max:1.5',
            'volume'             => 'sometimes|numeric|min:0|max:1',
            'text_scale'         => 'sometimes|numeric|min:0.8|max:1.6',
            'reduced_animations' => 'sometimes|boolean',
            'auto_play_next'     => 'sometimes|boolean',
            'read_along'         => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        $settings = $profile->childSettings
            ?? ChildSettings::create(['child_id' => $profile->child_id]);
        $settings->fill($validator->validated())->save();

        return $this->successResponse('Settings updated', $this->serializeSettings($settings));
    }

    private function ownedProfile(Request $request, string $id): ?ChildProfile
    {
        $caregiver = $request->get('auth_caregiver');
        return $caregiver->childProfiles()->where('child_id', $id)->first();
    }

    private function serializeSettings(ChildSettings $s): array
    {
        return [
            'setting_id'         => $s->setting_id,
            'child_id'           => $s->child_id,
            'narrator_voice'     => $s->narrator_voice,
            'reading_speed'      => (float) $s->reading_speed,
            'volume'             => (float) $s->volume,
            'text_scale'         => (float) $s->text_scale,
            'reduced_animations' => (bool) $s->reduced_animations,
            'auto_play_next'     => (bool) $s->auto_play_next,
            'read_along'         => (bool) $s->read_along,
        ];
    }

    private function serialize(ChildProfile $p): array
    {
        return [
            'child_id'          => $p->child_id,
            'caregiver_id'      => $p->caregiver_id,
            'name'              => $p->name,
            'age'               => $p->age,
            'avatar_emoji'      => $p->avatar_emoji,
            'avatar_color'      => $p->avatar_color,
            'favorite_genre'    => $p->favorite_genre,
            'listening_minutes' => $p->listening_minutes,
            'created_at'        => $p->created_at?->format('Y-m-d H:i:s'),
            'updated_at'        => $p->updated_at?->format('Y-m-d H:i:s'),
        ];
    }
}
