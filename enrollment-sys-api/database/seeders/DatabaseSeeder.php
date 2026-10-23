<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Order matters: schedules need courses, and enrollments (later) need users + schedules.
     */
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
            CourseSeeder::class,
            ScheduleSeeder::class,
            AnnouncementSeeder::class,
        ]);
    }
}
