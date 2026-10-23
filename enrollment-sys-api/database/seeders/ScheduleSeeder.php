<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ScheduleSeeder extends Seeder
{
    /** Standard class times per shift. */
    private const TIMES = [
        'morning'   => ['07:30:00', '09:00:00'],
        'afternoon' => ['13:30:00', '15:00:00'],
        'evening'   => ['17:30:00', '19:00:00'],
    ];

    private const MWF = ['Mon', 'Wed', 'Fri'];
    private const TTS = ['Tue', 'Thu', 'Sat'];
    private const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    private const WEEKEND = ['Sat', 'Sun'];

    public function run(): void
    {
        $now = now();

        // course title => list of [teacher, room, shift, days, capacity]
        $plan = [
            'General English Program' => [
                ['Ms. Sreymom Vuth',     'A101', 'morning',   self::MWF,      30],
                ['Mr. David Carter',     'A102', 'afternoon', self::TTS,      30],
                ['Ms. Sreymom Vuth',     'A101', 'evening',   self::MWF,      35],
            ],
            'IELTS Prep' => [
                ['Mr. Piseth Ouk',       'A201', 'morning',   self::WEEKDAYS, 20],
                ['Ms. Emily Johnson',    'A202', 'evening',   self::TTS,      20],
            ],
            'TOEIC Preparation' => [
                ['Ms. Kunthea Roth',     'A203', 'afternoon', self::MWF,      25],
                ['Ms. Kunthea Roth',     'A203', 'evening',   self::TTS,      25],
            ],
            'Business English' => [
                ['Mr. Samnang Chhun',    'A204', 'evening',   self::MWF,      20],
            ],
            'Basic Computer Skills' => [
                ['Mr. Rotha Meas',       'B101', 'morning',   self::MWF,      25],
                ['Mr. Rotha Meas',       'B101', 'afternoon', self::TTS,      25],
                ['Ms. Leakhena Tep',     'B102', 'evening',   self::MWF,      25],
            ],
            'Graphic Design (Photoshop & Illustrator)' => [
                ['Ms. Pich Sopheary',    'B201', 'afternoon', self::MWF,      20],
                ['Ms. Pich Sopheary',    'B201', 'evening',   self::TTS,      20],
            ],
            'Python Programming' => [
                ['Mr. Vibol Keo',        'B202', 'morning',   self::TTS,      25],
                ['Mr. Vibol Keo',        'B202', 'evening',   self::MWF,      25],
            ],
            'Full-Stack Web Dev' => [
                ['Mr. Sovann Hout',      'LAB1', 'morning',   self::WEEKDAYS, 20],
                ['Mr. Sovann Hout',      'LAB1', 'evening',   self::WEEKDAYS, 20],
                ['Mr. Dara Phan',        'LAB2', 'morning',   self::WEEKEND,  18],
            ],
            'Mobile App Development with Flutter' => [
                ['Ms. Chenda Ly',        'LAB2', 'afternoon', self::MWF,      18],
                ['Ms. Chenda Ly',        'LAB2', 'evening',   self::TTS,      18],
            ],
        ];

        $rows = [];

        foreach ($plan as $title => $slots) {
            $courseId = DB::table('courses')->where('title', $title)->value('id');

            if (! $courseId) {
                $this->command?->warn("Course not found, skipping schedules: {$title}");
                continue;
            }

            foreach ($slots as [$teacher, $room, $shift, $days, $capacity]) {
                [$start, $end] = self::TIMES[$shift];

                // Weekend classes run longer: 08:00-11:00
                if ($days === self::WEEKEND) {
                    $start = '08:00:00';
                    $end   = '11:00:00';
                }

                $rows[] = [
                    'course_id'    => $courseId,
                    'teacher_name' => $teacher,
                    'room_number'  => $room,
                    'shift'        => $shift,
                    'days'         => json_encode($days),
                    'start_time'   => $start,
                    'end_time'     => $end,
                    'max_capacity' => $capacity,
                    'created_at'   => $now,
                    'updated_at'   => $now,
                ];
            }
        }

        DB::table('schedules')->insert($rows);
    }
}
