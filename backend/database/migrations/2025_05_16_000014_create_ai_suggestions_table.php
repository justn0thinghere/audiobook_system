<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Per-child cache of the most recent Gemini suggestion run (UC-9).
     *
     * One row per child (the unique constraint) — every analyse run UPSERTs
     * this row, so the table is always the "latest snapshot". Per-item accept
     * / edit / dismiss state lives inside the `items` JSON so the caregiver
     * can resolve each suggestion independently without us needing a second
     * row-per-item table.
     */
    public function up(): void
    {
        Schema::create('ai_suggestions', function (Blueprint $table) {
            $table->uuid('suggestion_id')->primary();
            $table->foreignUuid('child_id')
                ->unique()
                ->constrained('child_profiles', 'child_id')
                ->cascadeOnDelete();
            // Stats sent to Gemini for this run — kept so the caregiver can see
            // what the suggestions were based on (transparency).
            $table->json('source_stats');
            // List of suggestion items. Each item: { id, setting_key,
            // current_value, suggested_value, reason, status }.
            $table->json('items');
            $table->enum('confidence', ['low', 'normal'])->default('normal');
            // True when this snapshot is from a previous successful run that we
            // re-served because the most recent analyse call failed (E2).
            $table->boolean('is_stale')->default(false);
            $table->timestamp('generated_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_suggestions');
    }
};
