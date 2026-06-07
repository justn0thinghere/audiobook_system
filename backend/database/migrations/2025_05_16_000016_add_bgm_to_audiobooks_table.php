<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('audiobooks', function (Blueprint $table) {
            $table->uuid('track_id')->nullable()->after('tags');
            $table->unsignedSmallInteger('bgm_volume')->default(30)->after('track_id'); // 0-100
            $table->foreign('track_id')->references('track_id')->on('music_tracks')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('audiobooks', function (Blueprint $table) {
            $table->dropForeign(['track_id']);
            $table->dropColumn(['track_id', 'bgm_volume']);
        });
    }
};
