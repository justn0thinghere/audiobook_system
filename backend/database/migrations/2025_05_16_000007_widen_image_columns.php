<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * AI illustrations are stored as image URLs (which can be long), so widen the
 * image columns from VARCHAR(500) to VARCHAR(1000).
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE `audiobooks` MODIFY `cover_image` VARCHAR(1000) NULL');
        DB::statement('ALTER TABLE `audiobook_pages` MODIFY `image` VARCHAR(1000) NULL');
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE `audiobooks` MODIFY `cover_image` VARCHAR(500) NULL');
        DB::statement('ALTER TABLE `audiobook_pages` MODIFY `image` VARCHAR(500) NULL');
    }
};
