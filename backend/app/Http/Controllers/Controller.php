<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;

abstract class Controller
{
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
}
