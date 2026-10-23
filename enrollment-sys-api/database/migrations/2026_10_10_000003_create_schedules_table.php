<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('schedules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('course_id')->constrained('courses')->cascadeOnDelete();
            $table->string('teacher_name');
            $table->string('room_number', 20);
            $table->enum('shift', ['morning', 'afternoon', 'evening']);
            $table->json('days');                                  // e.g. ["Mon","Wed","Fri"]
            $table->time('start_time');
            $table->time('end_time');
            $table->unsignedSmallInteger('max_capacity')->default(30);
            $table->timestamps();

            $table->index(['course_id', 'shift']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('schedules');
    }
};
