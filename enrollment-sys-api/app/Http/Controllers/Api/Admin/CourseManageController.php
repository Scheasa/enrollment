<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Resources\CourseResource;
use App\Models\Course;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CourseManageController extends Controller
{
    use ApiResponses;

    /** GET /api/admin/courses  (all courses, including hidden ones) */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'category'  => ['nullable', 'in:computer,english'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $courses = Course::withCount('schedules')
            ->when($request->query('category'), fn ($q, $v) => $q->where('category', $v))
            ->when($request->has('is_active'), fn ($q) => $q->where('is_active', $request->boolean('is_active')))
            ->orderBy('category')
            ->orderBy('title')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $courses->map(fn ($c) => (new CourseResource($c))->resolve())->values(),
        ]);
    }

    /**
     * POST /api/admin/courses   (JSON, or multipart when sending a thumbnail)
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title'           => ['required', 'string', 'max:150'],
            'description'     => ['nullable', 'string', 'max:5000'],
            'category'        => ['required', 'in:computer,english'],
            'level'           => ['required', 'string', 'max:50'],
            'fee'             => ['required', 'numeric', 'min:0', 'max:99999'],
            'duration_months' => ['required', 'integer', 'min:1', 'max:60'],
            'thumbnail_image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'is_active'       => ['nullable', 'boolean'],
        ]);

        unset($data['thumbnail_image']);

        if ($request->hasFile('thumbnail_image')) {
            $data['thumbnail_image'] = $request->file('thumbnail_image')->store('thumbnails', 'public');
        }

        $course = Course::create($data)->refresh();

        return response()->json([
            'success' => true,
            'message' => 'Course created.',
            'data'    => (new CourseResource($course))->resolve(),
        ], 201);
    }

    /**
     * POST|PUT|PATCH /api/admin/courses/{id}
     * Send only the fields you want to change. When uploading a thumbnail use POST
     * (PHP does not read files from a PUT form-data request).
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $course = Course::find($id);

        if (! $course) {
            $this->fail('Course not found.', 404);
        }

        $data = $request->validate([
            'title'           => ['sometimes', 'required', 'string', 'max:150'],
            'description'     => ['sometimes', 'nullable', 'string', 'max:5000'],
            'category'        => ['sometimes', 'required', 'in:computer,english'],
            'level'           => ['sometimes', 'required', 'string', 'max:50'],
            'fee'             => ['sometimes', 'required', 'numeric', 'min:0', 'max:99999'],
            'duration_months' => ['sometimes', 'required', 'integer', 'min:1', 'max:60'],
            'thumbnail_image' => ['sometimes', 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'is_active'       => ['sometimes', 'required', 'boolean'],
        ]);

        unset($data['thumbnail_image']);

        if ($request->hasFile('thumbnail_image')) {
            if ($course->thumbnail_image) {
                Storage::disk('public')->delete($course->thumbnail_image);
            }
            $data['thumbnail_image'] = $request->file('thumbnail_image')->store('thumbnails', 'public');
        }

        $course->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Course updated.',
            'data'    => (new CourseResource($course->fresh()))->resolve(),
        ]);
    }

    /**
     * DELETE /api/admin/courses/{id}
     * A course that already has enrollments is hidden (is_active = false) instead of
     * deleted, so student history and payments are never lost.
     */
    public function destroy(int $id): JsonResponse
    {
        $course = Course::find($id);

        if (! $course) {
            $this->fail('Course not found.', 404);
        }

        if ($course->enrollments()->exists()) {
            $course->update(['is_active' => false]);

            return response()->json([
                'success' => true,
                'message' => 'This course has enrollments, so it was hidden instead of deleted.',
                'hidden'  => true,
            ]);
        }

        if ($course->thumbnail_image) {
            Storage::disk('public')->delete($course->thumbnail_image);
        }

        $course->delete();   // its schedules are removed by the foreign key cascade

        return response()->json([
            'success' => true,
            'message' => 'Course deleted.',
            'hidden'  => false,
        ]);
    }
}