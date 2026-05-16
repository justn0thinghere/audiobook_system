<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('listening_history', function (Blueprint $table) {
            $table->uuid('history_id')->primary();
            $table->foreignUuid('child_id')
                ->constrained('child_profiles', 'child_id')
                ->cascadeOnDelete();
            $table->char('audiobook_id', 36); // UUID matching audiobooks.audiobook_id
            $table->unsignedInteger('duration_seconds')->default(0);
            $table->unsignedInteger('last_position_seconds')->default(0);
            $table->enum('mood', ['happy', 'calm', 'curious', 'sleepy'])->nullable();
            $table->boolean('completed')->default(false);
            $table->timestamps();

            $table->index(['child_id', 'audiobook_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('listening_history');
    }
};
