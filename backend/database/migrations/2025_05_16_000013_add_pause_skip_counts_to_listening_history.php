<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Tracks every pause-tap and forward-seek the child made during a listening
     * session. Used by UC-9 (Analyse Listening Behaviour) to derive pause rate
     * and skip rate per child for Gemini's sensory-preference analysis.
     */
    public function up(): void
    {
        Schema::table('listening_history', function (Blueprint $table) {
            $table->unsignedInteger('pause_count')->default(0)->after('completed');
            $table->unsignedInteger('skip_count')->default(0)->after('pause_count');
        });
    }

    public function down(): void
    {
        Schema::table('listening_history', function (Blueprint $table) {
            $table->dropColumn(['pause_count', 'skip_count']);
        });
    }
};
