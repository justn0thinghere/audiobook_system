<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     *
     * Caregivers register via the API (auth/register) so there's no
     * default seed account. Add one manually from the mobile app.
     */
    public function run(): void
    {
        // Intentionally empty.
    }
}
