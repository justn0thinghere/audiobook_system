<?php

namespace App\Http\Controllers\Api;

use App\Models\CaregiverSettings;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SettingsController extends ApiController
{
    public function show(Request $request): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        $this->logEvent('Settings', 'show called', [
            'caregiver_id' => $caregiver->caregiver_id,
        ]);
        $settings = $caregiver->settings
            ?? CaregiverSettings::create(['caregiver_id' => $caregiver->caregiver_id]);
        return $this->successResponse('OK', $this->serialize($settings));
    }

    public function update(Request $request): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        $this->logEvent('Settings', 'update called', [
            'caregiver_id' => $caregiver->caregiver_id,
            'fields'       => array_keys($request->all()),
        ]);

        $validator = Validator::make($request->all(), [
            'narrator_voice'     => 'sometimes|in:' . implode(',', CaregiverSettings::ALLOWED_VOICES),
            'reading_speed'      => 'sometimes|numeric|min:0.5|max:2.0',
            'volume'             => 'sometimes|numeric|min:0|max:1',
            'reduced_animations' => 'sometimes|boolean',
            'auto_play_next'     => 'sometimes|boolean',
            'read_along'         => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            $this->logWarn('Settings', 'update validation failed', [
                'errors' => $validator->errors()->all(),
            ]);
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        $settings = $caregiver->settings
            ?? CaregiverSettings::create(['caregiver_id' => $caregiver->caregiver_id]);
        $settings->fill($validator->validated())->save();

        $this->logEvent('Settings', 'update success', [
            'caregiver_id' => $caregiver->caregiver_id,
        ]);
        return $this->successResponse('Settings updated', $this->serialize($settings));
    }

    public function changePin(Request $request): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        $this->logEvent('Settings', 'changePin called', [
            'caregiver_id' => $caregiver->caregiver_id,
        ]);

        $validator = Validator::make($request->all(), [
            'current_pin' => 'required|digits:4',
            'new_pin'     => 'required|digits:4',
        ]);

        if ($validator->fails()) {
            $this->logWarn('Settings', 'changePin validation failed', [
                'errors' => $validator->errors()->all(),
            ]);
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        if (!$caregiver->verifyPin($request->input('current_pin'))) {
            $this->logWarn('Settings', 'changePin current PIN mismatch', [
                'caregiver_id' => $caregiver->caregiver_id,
            ]);
            return $this->errorResponse('Current PIN is incorrect', 'INVALID_PIN', 401);
        }

        $caregiver->pin = $request->input('new_pin');
        $caregiver->save();

        $this->logEvent('Settings', 'changePin success', [
            'caregiver_id' => $caregiver->caregiver_id,
        ]);
        return $this->successResponse('PIN updated');
    }

    private function serialize(CaregiverSettings $s): array
    {
        return [
            'setting_id'         => $s->setting_id,
            'caregiver_id'       => $s->caregiver_id,
            'narrator_voice'     => $s->narrator_voice,
            'reading_speed'      => (float) $s->reading_speed,
            'volume'             => (float) $s->volume,
            'reduced_animations' => (bool) $s->reduced_animations,
            'auto_play_next'     => (bool) $s->auto_play_next,
            'read_along'         => (bool) $s->read_along,
        ];
    }
}
