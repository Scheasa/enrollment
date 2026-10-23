<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CourseSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $courses = [
            // ---------------- English ----------------
            [
                'title'           => 'General English Program',
                'description'     => 'Build speaking, listening, reading and writing skills from the ground up. Suitable for students, job seekers and anyone preparing to study or work abroad.',
                'category'        => 'english',
                'level'           => 'Beginner',
                'fee'             => 240.00,
                'duration_months' => 6,
            ],
            [
                'title'           => 'IELTS Prep',
                'description'     => 'Intensive preparation for the IELTS Academic exam with weekly mock tests, speaking practice and band-score strategies. Ideal for scholarship and overseas study applicants.',
                'category'        => 'english',
                'level'           => 'Intermediate',
                'fee'             => 180.00,
                'duration_months' => 3,
            ],
            [
                'title'           => 'TOEIC Preparation',
                'description'     => 'Focused training on listening and reading sections of the TOEIC test, commonly required by employers and international companies in Cambodia.',
                'category'        => 'english',
                'level'           => 'Intermediate',
                'fee'             => 150.00,
                'duration_months' => 3,
            ],
            [
                'title'           => 'Business English',
                'description'     => 'Practical English for the workplace: emails, meetings, presentations, negotiations and job interviews.',
                'category'        => 'english',
                'level'           => 'Advanced',
                'fee'             => 200.00,
                'duration_months' => 4,
            ],

            // ---------------- Computer ----------------
            [
                'title'           => 'Basic Computer Skills',
                'description'     => 'Learn Windows, Microsoft Word, Excel, PowerPoint, email and safe internet use. Perfect for beginners and office staff.',
                'category'        => 'computer',
                'level'           => 'Beginner',
                'fee'             => 60.00,
                'duration_months' => 2,
            ],
            [
                'title'           => 'Graphic Design (Photoshop & Illustrator)',
                'description'     => 'Create logos, posters, social media content and print-ready designs using Adobe Photoshop and Illustrator.',
                'category'        => 'computer',
                'level'           => 'Beginner',
                'fee'             => 200.00,
                'duration_months' => 4,
            ],
            [
                'title'           => 'Python Programming',
                'description'     => 'Learn programming fundamentals with Python: variables, loops, functions, OOP, file handling and small real-world projects.',
                'category'        => 'computer',
                'level'           => 'Beginner',
                'fee'             => 250.00,
                'duration_months' => 4,
            ],
            [
                'title'           => 'Full-Stack Web Dev',
                'description'     => 'Become a job-ready web developer: HTML, CSS, JavaScript, Laravel, MySQL, REST APIs and deployment. Includes a final team project.',
                'category'        => 'computer',
                'level'           => 'Intermediate',
                'fee'             => 450.00,
                'duration_months' => 6,
            ],
            [
                'title'           => 'Mobile App Development with Flutter',
                'description'     => 'Build Android and iOS apps with Flutter and Dart, connect to REST APIs, and publish your first app.',
                'category'        => 'computer',
                'level'           => 'Intermediate',
                'fee'             => 400.00,
                'duration_months' => 5,
            ],
        ];

        $rows = array_map(fn ($c) => $c + [
            'thumbnail_image' => null,
            'is_active'       => true,
            'created_at'      => $now,
            'updated_at'      => $now,
        ], $courses);

        DB::table('courses')->insert($rows);
    }
}
