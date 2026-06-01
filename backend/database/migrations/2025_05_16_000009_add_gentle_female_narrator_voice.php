<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Add the 'gentle_female' option to the caregiver_settings.narrator_voice
     * enum so caregivers can pick a second female narrator voice.
     */
    public function up(): void
    {
        DB::statement(
            "ALTER TABLE caregiver_settings MODIFY narrator_voice "
            . "ENUM('calm_female','gentle_female','warm_male','friendly_child','soothing_elder') "
            . "NOT NULL DEFAULT 'calm_female'"
        );
    }

    public function down(): void
    {
        // Fall back any rows on the new voice before narrowing the enum again.
        DB::table('caregiver_settings')
            ->where('narrator_voice', 'gentle_female')
            ->update(['narrator_voice' => 'calm_female']);

        DB::statement(
            "ALTER TABLE caregiver_settings MODIFY narrator_voice "
            . "ENUM('calm_female','warm_male','friendly_child','soothing_elder') "
            . "NOT NULL DEFAULT 'calm_female'"
        );
    }
};
