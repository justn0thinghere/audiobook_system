<?php

namespace App\Http\Middleware;

use App\Models\Caregiver;
use Carbon\Carbon;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class SessionAuthMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        try {
            $authHeader = $request->header('Authorization');

            if (!$authHeader) {
                return $this->unauthorized('Authorization header missing', 'MISSING_AUTH_HEADER');
            }

            $token = str_starts_with($authHeader, 'Bearer ')
                ? substr($authHeader, 7)
                : $authHeader;

            if (!$token) {
                return $this->unauthorized('Invalid authorization format', 'INVALID_AUTH_FORMAT');
            }

            $caregiver = Caregiver::where('session_token', $token)
                ->where('session_expires', '>', Carbon::now('Asia/Kuala_Lumpur'))
                ->where('is_active', true)
                ->first();

            if (!$caregiver) {
                Log::warning('Invalid or expired session token attempt', [
                    'token_prefix' => substr($token, 0, 10) . '...',
                    'ip' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                ]);
                return $this->unauthorized('Invalid or expired session token', 'INVALID_SESSION');
            }

            // Sliding expiry: if less than 1h left, extend by 24h.
            $minutesLeft = Carbon::now('Asia/Kuala_Lumpur')->diffInMinutes($caregiver->session_expires, false);
            if ($minutesLeft < 60) {
                $caregiver->session_expires = Carbon::now('Asia/Kuala_Lumpur')->addHours(24);
                $caregiver->save();
            }

            $request->merge(['auth_caregiver' => $caregiver]);

            return $next($request);
        } catch (\Throwable $e) {
            Log::error('SessionAuthMiddleware error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return $this->unauthorized('Authentication failed', 'AUTH_ERROR');
        }
    }

    private function unauthorized(string $message, string $errorCode): Response
    {
        return response()->json([
            'status' => 'ERROR',
            'message' => $message,
            'error_code' => $errorCode,
            'timestamp' => now('Asia/Kuala_Lumpur')->format('Y-m-d H:i:s'),
        ], 401);
    }
}
