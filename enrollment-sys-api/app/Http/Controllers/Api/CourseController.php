<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CourseResource;
use App\Http\Resources\ScheduleResource;
use App\Models\Course;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CourseController extends Controller
{
    /**
     * GET /api/courses
     * Optional query params: category=computer|english, level=Beginner, search=ielts
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'category' => ['nullable', 'in:computer,english'],
            'level'    => ['nullable', 'string', 'max:50'],
            'search'   => ['nullable', 'string', 'max:100'],
        ]);

        $courses = Course::active()
            ->category($request->query('category'))
            ->when($request->query('level'), fn ($q, $level) => $q->where('level', $level))
            ->when($request->query('search'), fn ($q, $s) => $q->where('title', 'like', "%{$s}%"))
            ->withCount('schedules')
            ->orderBy('category')
            ->orderBy('title')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $courses->map(fn ($c) => (new CourseResource($c))->resolve())->values(),
        ]);
    }

    /**
     * GET /api/courses/{id}
     * Course detail including all its schedules (with seats available).
     */
    public function show(int $id): JsonResponse
    {
        $course = Course::active()
            ->with(['schedules' => fn ($q) => $q->withSeatCount()->orderBy('shift')->orderBy('start_time')])
            ->withCount('schedules')
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => (new CourseResource($course))->resolve(),
        ]);
    }

    /**
     * GET /api/courses/{id}/schedules
     * Optional query param: shift=morning|afternoon|evening
     */
    public function schedules(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'shift' => ['nullable', 'in:morning,afternoon,evening'],
        ]);

        $course = Course::active()->findOrFail($id);

        $schedules = $course->schedules()
            ->withSeatCount()
            ->when($request->query('shift'), fn ($q, $shift) => $q->where('shift', $shift))
            ->orderBy('shift')
            ->orderBy('start_time')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $schedules->map(fn ($s) => (new ScheduleResource($s))->resolve())->values(),
        ]);
    }
}