<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('music_tracks', function (Blueprint $table) {
            $table->uuid('track_id')->primary();
            $table->string('title', 200);
            $table->string('composer', 200)->nullable();
            $table->string('file_path', 500);
            $table->string('tags', 500)->default('');   // comma-separated mood tags
            $table->string('tempo', 50)->nullable();     // e.g. "slow", "moderate", "upbeat"
            $table->unsignedInteger('duration_secs')->nullable();
            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('music_tracks');
    }
};
