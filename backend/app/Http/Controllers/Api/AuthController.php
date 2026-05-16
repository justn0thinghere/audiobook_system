<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Caregiver;
use App\Models\CaregiverSettings;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name'          => 'required|string|max:100',
            'pin'           => 'required|digits:4',
            'email'         => 'nullable|email|max:150|unique:caregivers,email',
            'mobile_number' => 'nullable|string|max:20|unique:caregivers,mobile_number',
            'device_id'     => 'nullable|string|max:255',
            'device_name'   => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        try {
            $caregiver = Caregiver::create([
                'name'          => $request->input('name'),
                'email'         => $request->input('email'),
                'mobile_number' => $request->input('mobile_number'),
                'pin'           => $request->input('pin'),
                'device_id'     => $request->input('device_id'),
                'device_name'   => $request->input('device_name'),
                'is_active'     => true,
            ]);

            // Create default settings row.
            CaregiverSettings::create(['caregiver_id' => $caregiver->caregiver_id]);

            return $this->loginCaregiver($caregiver, $request);
        } catch (\Throwable $e) {
            Log::error('Register error', ['error' => $e->getMessage()]);
            return $this->errorResponse('Could not register caregiver', 'REGISTER_FAILED', 500);
        }
    }

    public function loginWithPin(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'pin'           => 'required|digits:4',
            'email'         => 'nullable|email',
            'mobile_number' => 'nullable|string|max:20',
            'device_id'     => 'nullable|string|max:255',
            'device_name'   => 'nullable|string|max:255',
            'fcm_token'     => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed: ' . implode(', ', $validator->errors()->all()),
                'VALIDATION_ERROR',
                422
            );
        }

        // Identify the caregiver: by email, mobile, or fallback to a single-caregiver demo flow.
        $query = Caregiver::query()->where('is_active', true);
        if ($request->filled('email')) {
            $query->where('email', $request->input('email'));
        } elseif ($request->filled('mobile_number')) {
            $query->where('mobile_number', $request->input('mobile_number'));
        } else {
            // No identifier — only works if exactly one caregiver exists.
            if (Caregiver::where('is_active', true)->count() !== 1) {
                return $this->errorResponse(
                    'Please provide email or mobile number',
                    'IDENTIFIER_REQUIRED',
                    422
                );
            }
        }

        $caregiver = $query->first();
        if (!$caregiver || !$caregiver->verifyPin($request->input('pin'))) {
            return $this->errorResponse('Invalid credentials', 'INVALID_CREDENTIALS', 401);
        }

        return $this->loginCaregiver($caregiver, $request);
    }

    private function loginCaregiver(Caregiver $caregiver, Request $request): JsonResponse
    {
        $token = Str::random(64);

        $caregiver->session_token   = $token;
        $caregiver->session_expires = Carbon::now('Asia/Kuala_Lumpur')->addHours(24);
        $caregiver->last_login_at   = Carbon::now('Asia/Kuala_Lumpur');
        if ($request->filled('device_id')) {
            $caregiver->device_id = $request->input('device_id');
        }
        if ($request->filled('device_name')) {
            $caregiver->device_name = $request->input('device_name');
        }
        if ($request->filled('fcm_token')) {
            $caregiver->fcm_token = $request->input('fcm_token');
        }
        $caregiver->save();

        return $this->successResponse('Login successful', [
            'session_token'   => $token,
            'session_expires' => $caregiver->session_expires->format('Y-m-d H:i:s'),
            'caregiver' => [
                'caregiver_id'  => $caregiver->caregiver_id,
                'name'          => $caregiver->name,
                'email'         => $caregiver->email,
                'mobile_number' => $caregiver->mobile_number,
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        return $this->successResponse('OK', [
            'caregiver_id'  => $caregiver->caregiver_id,
            'name'          => $caregiver->name,
            'email'         => $caregiver->email,
            'mobile_number' => $caregiver->mobile_number,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        $caregiver->session_token   = null;
        $caregiver->session_expires = null;
        $caregiver->save();
        return $this->successResponse('Logged out');
    }

    public function verifyPin(Request $request): JsonResponse
    {
        $pin = (string) $request->input('pin');
        if (!preg_match('/^\d{4}$/', $pin)) {
            return $this->errorResponse('PIN must be 4 digits', 'VALIDATION_ERROR', 422);
        }
        $caregiver = $request->get('auth_caregiver');
        if (!$caregiver->verifyPin($pin)) {
            return $this->errorResponse('Invalid PIN', 'INVALID_PIN', 401);
        }
        return $this->successResponse('OK');
    }
}
