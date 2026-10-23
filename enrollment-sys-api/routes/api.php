<?php

use App\Http\Controllers\Api\Admin\AnnouncementManageController;
use App\Http\Controllers\Api\Admin\CourseManageController;
use App\Http\Controllers\Api\Admin\DashboardController;
use App\Http\Controllers\Api\Admin\EnrollmentReviewController;
use App\Http\Controllers\Api\Admin\PaymentReviewController;
use App\Http\Controllers\Api\Admin\ScheduleManageController;
use App\Http\Controllers\Api\Admin\UserManageController;
use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CourseController;
use App\Http\Controllers\Api\EnrollmentController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ScheduleController;
use Illuminate\Support\Facades\Route;

// {id} must be a number everywhere in this file
Route::pattern('id', '[0-9]+');

Route::get('/ping', fn () => response()->json(['message' => 'API is running']));
// Auth
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
});

Route::apiResource('courses', CourseController::class)
    ->only(['index', 'show'])
    ->parameters(['courses' => 'id']);
Route::get('/courses/{id}/schedules', [CourseController::class, 'schedules'])
    ->name('courses.schedules');

Route::apiResource('schedules', ScheduleController::class)
    ->only(['show'])
    ->parameters(['schedules' => 'id']);

Route::apiResource('announcements', AnnouncementController::class)
    ->only(['index', 'show'])
    ->parameters(['announcements' => 'id']);

// | Logged-in users (Authorization: Bearer <token>)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [ProfileController::class, 'show']);
    Route::match(['put', 'patch', 'post'], '/me', [ProfileController::class, 'update']);
    Route::post('/me/password', [ProfileController::class, 'changePassword'])->middleware('throttle:5,1');

    // Enrollments (student's own)
    Route::apiResource('enrollments', EnrollmentController::class)
        ->only(['index', 'store', 'show'])
        ->parameters(['enrollments' => 'id']);
    Route::post('/enrollments/{id}/drop', [EnrollmentController::class, 'drop'])
        ->name('enrollments.drop');

    // Payments (student's own)
    Route::apiResource('payments', PaymentController::class)
        ->only(['index', 'store', 'show'])
        ->parameters(['payments' => 'id']);
});

Route::middleware(['auth:sanctum', 'role:admin,staff'])
    ->prefix('admin')
    ->name('admin.')
    ->group(function () {
        Route::get('/ping', fn () => response()->json([
            'success' => true,
            'message' => 'Staff area OK',
        ]));

        Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

        // Enrollment review
        Route::apiResource('enrollments', EnrollmentReviewController::class)
            ->only(['index', 'show'])
            ->parameters(['enrollments' => 'id']);
        Route::post('/enrollments/{id}/approve', [EnrollmentReviewController::class, 'approve'])
            ->name('enrollments.approve');
        Route::post('/enrollments/{id}/reject', [EnrollmentReviewController::class, 'reject'])
            ->name('enrollments.reject');

        // Payment review
        Route::apiResource('payments', PaymentReviewController::class)
            ->only(['index', 'show'])
            ->parameters(['payments' => 'id']);
        Route::post('/payments/{id}/verify', [PaymentReviewController::class, 'verify'])
            ->name('payments.verify');
        Route::post('/payments/{id}/reject', [PaymentReviewController::class, 'reject'])
            ->name('payments.reject');

        // Courses
        Route::apiResource('courses', CourseManageController::class)
            ->only(['index', 'store', 'destroy'])
            ->parameters(['courses' => 'id']);
        Route::match(['put', 'patch', 'post'], '/courses/{id}', [CourseManageController::class, 'update'])
            ->name('courses.update');

        // Schedules
        Route::apiResource('schedules', ScheduleManageController::class)
            ->only(['index', 'store', 'destroy'])
            ->parameters(['schedules' => 'id']);
        Route::match(['put', 'patch', 'post'], '/schedules/{id}', [ScheduleManageController::class, 'update'])
            ->name('schedules.update');

        // Announcements
        Route::apiResource('announcements', AnnouncementManageController::class)
            ->only(['index', 'store', 'destroy'])
            ->parameters(['announcements' => 'id']);
        Route::match(['put', 'patch', 'post'], '/announcements/{id}', [AnnouncementManageController::class, 'update'])
            ->name('announcements.update');
    });
    // admin
Route::middleware(['auth:sanctum', 'role:admin'])
    ->prefix('admin')
    ->name('admin.')
    ->group(function () {
        Route::apiResource('users', UserManageController::class)
            ->only(['index', 'store', 'destroy'])
            ->parameters(['users' => 'id']);
        Route::match(['put', 'patch', 'post'], '/users/{id}', [UserManageController::class, 'update'])
            ->name('users.update');
    });