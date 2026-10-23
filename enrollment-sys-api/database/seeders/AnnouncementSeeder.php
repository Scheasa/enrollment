<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AnnouncementSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $items = [
            [
                'title'   => 'Enrollment Open for the November Intake',
                'content' => 'Registration for our November intake is now open. Choose your course and shift in the app, pay by ABA, ACLEDA or Wing, and upload your transfer receipt. Our staff will verify your payment within one working day.',
            ],
            [
                'title'   => 'Free IELTS Mock Test This Saturday',
                'content' => 'Join our free IELTS mock test this Saturday at 8:00 AM in Room A201. Seats are limited to 20 students, so please enroll in IELTS Prep to reserve your spot and receive your detailed band-score feedback.',
            ],
            [
                'title'   => 'New Class: Mobile App Development with Flutter',
                'content' => 'A new evening class for Mobile App Development with Flutter is opening soon in Lab 2. Learn to build Android and iOS apps connected to real REST APIs. Limited to 18 students per class.',
            ],
        ];

        $rows = array_map(fn ($a) => $a + [
            'image'      => null,
            'is_active'  => true,
            'created_at' => $now,
            'updated_at' => $now,
        ], $items);

        DB::table('announcements')->insert($rows);
    }
}