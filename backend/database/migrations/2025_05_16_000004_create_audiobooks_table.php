<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audiobooks', function (Blueprint $table) {
            $table->uuid('audiobook_id')->primary();
            $table->string('title', 255);
            $table->string('author', 100)->nullable();
            $table->text('description')->nullable();
            $table->string('topic', 100)->nullable();
            $table->string('category', 100)->nullable();
            $table->enum('difficulty', ['easy', 'medium', 'hard'])->default('easy');
            $table->enum('type', ['Audio', 'Text'])->default('Text');
            $table->longText('content_text')->nullable();
            $table->string('audio_file', 500)->nullable();
            $table->string('source_file', 500)->nullable();
            $table->string('cover_image', 500)->nullable();
            $table->unsignedInteger('duration_minutes')->nullable();
            $table->string('language', 50)->nullable()->default('en');
            $table->string('age_group', 50)->nullable();
            $table->string('tags', 500)->nullable();
            $table->boolean('is_generated')->default(false);
            $table->boolean('is_user_uploaded')->default(false);
            $table->enum('status', ['available', 'processing', 'failed'])->default('available');
            $table->timestamps();

            $table->index('category');
            $table->index('age_group');
            $table->index('is_generated');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audiobooks');
    }
};
