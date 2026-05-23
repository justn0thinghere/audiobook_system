<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audiobook_pages', function (Blueprint $table) {
            $table->uuid('page_id')->primary();
            $table->foreignUuid('audiobook_id')
                ->constrained('audiobooks', 'audiobook_id')
                ->cascadeOnDelete();
            $table->unsignedInteger('page_number')->default(1);
            $table->text('text')->nullable();
            $table->string('image', 500)->nullable();
            $table->timestamps();

            $table->index(['audiobook_id', 'page_number']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audiobook_pages');
    }
};
