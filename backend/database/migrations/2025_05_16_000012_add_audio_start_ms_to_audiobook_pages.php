<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Offset (in milliseconds) from the start of the whole-book recording
     * where this page begins. Page 1 is implicitly 0. When pages 2..N have
     * this set, the player uses these exact boundaries to flip pages and
     * carve up the read-along word spans, instead of the word-count
     * heuristic that drifts on uneven narration pacing.
     */
    public function up(): void
    {
        Schema::table('audiobook_pages', function (Blueprint $table) {
            $table->unsignedInteger('audio_start_ms')->nullable()->after('image_prompt');
        });
    }

    public function down(): void
    {
        Schema::table('audiobook_pages', function (Blueprint $table) {
            $table->dropColumn('audio_start_ms');
        });
    }
};
