<?php
use App\Http\Controllers\Api\AudiobookController;
use App\Http\Controllers\Api\ContentManagementController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// API Routes Testing Endpoint
Route::post('/test', function () {
    return response()->json([
        'message' => 'API routing is working!',
        'timestamp' => now()->format('Y-m-d H:i:s')
    ]);
});


// API route for fetching audiobook data by ID
Route::prefix('audiobooks')->group(function () {
    Route::post('{id}', [AudiobookController::class, 'getAudiobookData']);
});

// API routes for content management
Route::prefix('content')->group(function () {
    Route::get('/summary', [ContentManagementController::class, 'getContentSummary']);
    Route::get('/list', [ContentManagementController::class, 'getContentList']);
    Route::post('/create', [ContentManagementController::class, 'createContent']);
});