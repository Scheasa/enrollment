<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('enrollments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('course_id')->constrained('courses')->cascadeOnDelete();
            $table->foreignId('schedule_id')->constrained('schedules')->cascadeOnDelete();
            $table->enum('status', ['pending', 'approved', 'rejected', 'dropped'])
                  ->default('pending')
                  ->index();
            $table->date('enrolled_date');
            $table->text('remarks')->nullable();
            $table->timestamps();

            // A student can only hold one enrollment row per schedule.
            // To re-enroll after "dropped", update the existing row's status instead of inserting.
            $table->unique(['student_id', 'schedule_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('enrollments');
    }
};
