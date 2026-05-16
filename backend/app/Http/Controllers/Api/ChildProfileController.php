<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChildProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ChildProfileController extends Controller
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
