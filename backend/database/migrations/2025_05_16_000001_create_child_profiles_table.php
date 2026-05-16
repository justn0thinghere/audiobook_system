<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('child_profiles', function (Blueprint $table) {
            $table->uuid('child_id')->primary();
            $table->foreignUuid('caregiver_id')
                ->constrained('caregivers', 'caregiver_id')
                ->cascadeOnDelete();
            $table->string('name');
            $table->unsignedTinyInteger('age');
            $table->string('avatar_emoji', 8)->default('🌟');
            $table->string('avatar_color', 9)->default('#F5D5DD');
            $table->string('favorite_genre', 50)->nullable();
            $table->unsignedInteger('listening_minutes')->default(0);
            $table->timestamps();

            $table->index('caregiver_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('child_profiles');
    }
};
