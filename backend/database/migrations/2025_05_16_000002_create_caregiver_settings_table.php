<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('caregiver_settings', function (Blueprint $table) {
            $table->uuid('setting_id')->primary();
            $table->foreignUuid('caregiver_id')
                ->unique()
                ->constrained('caregivers', 'caregiver_id')
                ->cascadeOnDelete();
            $table->enum('narrator_voice', [
                'calm_female',
                'warm_male',
                'friendly_child',
                'soothing_elder',
            ])->default('calm_female');
            $table->decimal('reading_speed', 3, 2)->default(1.00);
            $table->decimal('volume', 3, 2)->default(0.80);
            $table->boolean('reduced_animations')->default(true);
            $table->boolean('auto_play_next')->default(false);
            $table->boolean('read_along')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('caregiver_settings');
    }
};
