<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('courses', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->enum('category', ['computer', 'english'])->index();
            $table->string('level', 50)->default('Beginner'); // Beginner, Intermediate, Advanced, All Levels
            $table->decimal('fee', 10, 2);                     // total course fee in USD
            $table->unsignedTinyInteger('duration_months');
            $table->string('thumbnail_image')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('courses');
    }
};
