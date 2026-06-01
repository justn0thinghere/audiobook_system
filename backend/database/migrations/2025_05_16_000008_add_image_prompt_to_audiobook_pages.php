<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Store the AI image prompt per page so a background job can (re)generate the
 * illustration for that page after the story has already been saved.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('audiobook_pages', function (Blueprint $table) {
            $table->text('image_prompt')->nullable()->after('text');
        });
    }

    public function down(): void
    {
        Schema::table('audiobook_pages', function (Blueprint $table) {
            $table->dropColumn('image_prompt');
        });
    }
};
