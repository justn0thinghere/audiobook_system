<?php

use App\Http\Controllers\Api\AudiobookController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChildProfileController;
use App\Http\Controllers\Api\ContentManagementController;
use App\Http\Controllers\Api\InsightsController;
use App\Http\Controllers\Api\ListeningHistoryController;
use App\Http\Controllers\Api\SettingsController;
use App\Http\Controllers\Api\TtsController;
use Illuminate\Support\Facades\Route;

// Health check
Route::post('/test', function () {
    return response()->json([
        'status' => 'SUCCESS',
        'message' => 'API routing is working',
        'timestamp' => now('Asia/Kuala_Lumpur')->format('Y-m-d H:i:s'),
    ]);
});

// Public auth endpoints
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login',    [AuthController::class, 'loginWithPin']);
});

// All routes below require a valid session token.
Route::middleware('session.auth')->group(function () {
    Route::prefix('auth')->group(function () {
        Route::post('/me',         [AuthController::class, 'me']);
        Route::post('/logout',     [AuthController::class, 'logout']);
        Route::post('/verify-pin', [AuthController::class, 'verifyPin']);
    });

    Route::prefix('settings')->group(function () {
        Route::post('/',           [SettingsController::class, 'show']);
        Route::post('/update',     [SettingsController::class, 'update']);
        Route::post('/change-pin', [SettingsController::class, 'changePin']);
    });

    Route::prefix('child-profiles')->group(function () {
        Route::post('/',                 [ChildProfileController::class, 'index']);
        Route::post('/create',           [ChildProfileController::class, 'store']);
        Route::post('/{childId}/update', [ChildProfileController::class, 'update'])->whereUuid('childId');
        Route::post('/{childId}/delete', [ChildProfileController::class, 'destroy'])->whereUuid('childId');
        Route::post('/{childId}/settings',        [ChildProfileController::class, 'showSettings'])->whereUuid('childId');
        Route::post('/{childId}/settings/update', [ChildProfileController::class, 'updateSettings'])->whereUuid('childId');
    });

    Route::prefix('audiobooks')->group(function () {
        Route::post('/{audiobookId}', [AudiobookController::class, 'getAudiobookData'])->whereUuid('audiobookId');
    });

    Route::prefix('content')->group(function () {
        Route::post('/summary',  [ContentManagementController::class, 'getContentSummary']);
        Route::post('/list',     [ContentManagementController::class, 'getContentList']);
        Route::post('/create',   [ContentManagementController::class, 'createContent']);
        Route::post('/generate', [ContentManagementController::class, 'generateContent']);
        Route::post('/{audiobookId}/pages',  [ContentManagementController::class, 'addPage'])->whereUuid('audiobookId');
        Route::post('/{audiobookId}/update', [ContentManagementController::class, 'update'])->whereUuid('audiobookId');
        Route::post('/{audiobookId}/delete', [ContentManagementController::class, 'destroy'])->whereUuid('audiobookId');
        Route::post('/{audiobookId}/pages/{pageId}/update', [ContentManagementController::class, 'updatePage'])->whereUuid(['audiobookId', 'pageId']);
        Route::post('/{audiobookId}/pages/{pageId}/delete', [ContentManagementController::class, 'deletePage'])->whereUuid(['audiobookId', 'pageId']);
    });

    Route::prefix('listening-history')->group(function () {
        Route::post('/record',            [ListeningHistoryController::class, 'record']);
        Route::post('/child/{childId}',   [ListeningHistoryController::class, 'forProfile'])->whereUuid('childId');
    });

    Route::prefix('insights')->group(function () {
        Route::post('/overview', [InsightsController::class, 'overview']);
        // UC-9 — Analyse Listening Behaviour. Per-child suggestions.
        Route::post('/{childId}/analyse',     [InsightsController::class, 'analyse'])->whereUuid('childId');
        Route::post('/{childId}/suggestions', [InsightsController::class, 'suggestions'])->whereUuid('childId');
        Route::post('/{childId}/suggestions/apply',   [InsightsController::class, 'applySuggestion'])->whereUuid('childId');
        Route::post('/{childId}/suggestions/dismiss', [InsightsController::class, 'dismissSuggestion'])->whereUuid('childId');
    });

    // Natural-voice narration
    Route::post('/tts/speak', [TtsController::class, 'speak']);
});
