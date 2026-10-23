<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\EnrollmentResource;
use App\Models\Enrollment;
use App\Models\Schedule;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EnrollmentController extends Controller
{
    /** Relations returned with every enrollment. */
    private const WITH = ['course', 'schedule', 'payments'];

    /**
     * GET /api/enrollments
     * The logged-in student's own enrollments. Optional: ?status=pending|approved|rejected|dropped
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'status' => ['nullable', 'in:pending,approved,rejected,dropped'],
        ]);

        $enrollments = Enrollment::where('student_id', $request->user()->id)
            ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
            ->with(self::WITH)
            ->latest('id')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $enrollments->map(fn ($e) => (new EnrollmentResource($e))->resolve())->values(),
        ]);
    }

    /**
     * GET /api/enrollments/{id}
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $enrollment = Enrollment::where('student_id', $request->user()->id)
            ->with(self::WITH)
            ->find($id);

        if (! $enrollment) {
            $this->fail('Enrollment not found.', 404);
        }

        return response()->json([
            'success' => true,
            'data'    => (new EnrollmentResource($enrollment))->resolve(),
        ]);
    }

    /**
     * POST /api/enrollments
     * Body: { "schedule_id": 1, "remarks": "optional" }
     * The course is taken from the schedule, so Flutter only sends schedule_id.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'student') {
            $this->fail('Only students can enroll in courses.', 403);
        }

        $data = $request->validate([
            'schedule_id' => ['required', 'integer', 'exists:schedules,id'],
            'remarks'     => ['nullable', 'string', 'max:500'],
        ]);

        $enrollment = DB::transaction(function () use ($user, $data) {
            // Lock the schedule row so two students cannot grab the last seat at the same time.
            $schedule = Schedule::with('course')->lockForUpdate()->findOrFail($data['schedule_id']);

            if (! $schedule->course->is_active) {
                $this->fail('This course is not open for enrollment.', 422);
            }

            // One active enrollment per course (any schedule/shift).
            $hasActive = Enrollment::where('student_id', $user->id)
                ->where('course_id', $schedule->course_id)
                ->whereIn('status', ['pending', 'approved'])
                ->exists();

            if ($hasActive) {
                $this->fail('You already have an active enrollment in this course.', 409);
            }

            if ($schedule->isFull()) {
                $this->fail('This schedule is full. Please choose another shift.', 409);
            }

            $values = [
                'status'        => 'pending',
                'enrolled_date' => now()->toDateString(),
                'remarks'       => $data['remarks'] ?? null,
            ];

            // enrollments has unique(student_id, schedule_id). If this student previously
            // had a rejected/dropped row for the same schedule, reuse it instead of inserting.
            $existing = Enrollment::where('student_id', $user->id)
                ->where('schedule_id', $schedule->id)
                ->first();

            if ($existing) {
                $existing->update($values);

                return $existing;
            }

            return Enrollment::create($values + [
                'student_id'  => $user->id,
                'course_id'   => $schedule->course_id,
                'schedule_id' => $schedule->id,
            ]);
        });

        $enrollment->load(self::WITH);

        return response()->json([
            'success' => true,
            'message' => 'Enrollment submitted. Please upload your payment receipt.',
            'data'    => (new EnrollmentResource($enrollment))->resolve(),
        ], 201);
    }

    /**
     * POST /api/enrollments/{id}/drop
     * Student cancels a pending or approved enrollment.
     */
    public function drop(Request $request, int $id): JsonResponse
    {
        $enrollment = Enrollment::where('student_id', $request->user()->id)->find($id);

        if (! $enrollment) {
            $this->fail('Enrollment not found.', 404);
        }

        if (! in_array($enrollment->status, ['pending', 'approved'], true)) {
            $this->fail("An enrollment that is {$enrollment->status} cannot be dropped.", 409);
        }

        $enrollment->update(['status' => 'dropped']);
        $enrollment->load(self::WITH);

        return response()->json([
            'success' => true,
            'message' => 'Enrollment dropped.',
            'data'    => (new EnrollmentResource($enrollment))->resolve(),
        ]);
    }

    /** Stop the request and answer with a JSON error (rolls back any open transaction). */
    private function fail(string $message, int $status): never
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $message,
        ], $status));
    }
}