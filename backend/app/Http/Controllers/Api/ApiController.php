<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

/**
 * Base controller for all /api endpoints. Provides the standard JSON
 * success/error envelope used across the API.
 */
abstract class ApiController
{
    /**
     * Emit a structured info-level log line tagged with a controller name so
     * the whole request lifecycle is greppable in laravel.log:
     *
     *   [Insights] analyse started {"child_id":"...","caregiver_id":"..."}
     *
     * Pair this with logWarn() / logError() below at decision points
     * (validation failed, not found, exception) for full traceability.
     */
    protected function logEvent(string $tag, string $event, array $context = []): void
    {
        Log::info("[{$tag}] {$event}", $context);
    }

    protected function logWarn(string $tag, string $event, array $context = []): void
    {
        Log::warning("[{$tag}] {$event}", $context);
    }

    protected function logError(string $tag, string $event, array $context = []): void
    {
        Log::error("[{$tag}] {$event}", $context);
    }

    protected function successResponse(string $message, mixed $data = null, int $statusCode = 200): JsonResponse
    {
        $payload = [
            'status' => 'SUCCESS',
            'message' => $message,
            'timestamp' => now('Asia/Kuala_Lumpur')->format('Y-m-d H:i:s'),
        ];
        if ($data !== null) {
            $payload['data'] = $data;
        }
        return response()->json($payload, $statusCode);
    }

    protected function errorResponse(string $message, string $errorCode = 'ERROR', int $statusCode = 400): JsonResponse
    {
        return response()->json([
            'status' => 'ERROR',
            'message' => $message,
            'error_code' => $errorCode,
            'timestamp' => now('Asia/Kuala_Lumpur')->format('Y-m-d H:i:s'),
        ], $statusCode);
    }

    /**
     * Build an absolute URL for a stored relative path (e.g. "storage/uploads/..").
     *
     * Uses the INCOMING request's scheme+host so the URL is always reachable by
     * whatever client is asking — Android emulator (10.0.2.2), a real phone on
     * Wi-Fi, etc. Already-absolute URLs (Gemini image links) pass through unchanged.
     */
    protected function mediaUrl(?string $path): ?string
    {
        if ($path === null || $path === '') {
            return null;
        }
        if (\Illuminate\Support\Str::startsWith($path, ['http://', 'https://'])) {
            return $path;
        }
        $base = rtrim(request()->getSchemeAndHttpHost(), '/');
        return $base . '/' . ltrim($path, '/');
    }
}
