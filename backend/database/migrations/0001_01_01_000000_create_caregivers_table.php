<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('caregivers', function (Blueprint $table) {
            $table->uuid('caregiver_id')->primary();
            $table->string('name');
            $table->string('email')->nullable()->unique();
            $table->string('mobile_number', 20)->nullable()->unique();
            $table->string('pin', 255); // bcrypt-hashed 4-digit PIN
            $table->string('device_id')->nullable();
            $table->string('device_name')->nullable();
            $table->string('fcm_token', 500)->nullable();
            $table->string('session_token', 100)->nullable()->index();
            $table->timestamp('session_expires')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('caregivers');
    }
};
