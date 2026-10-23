<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Resources\ScheduleResource;
use App\Models\Schedule;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ScheduleManageController extends Controller
{
    use ApiResponses;

    /** GET /api/admin/schedules?course_id=2 */
    public function index(Request $request): JsonResponse
    {
        $request->validate(['course_id' => ['nullable', 'integer']]);

        $schedules = Schedule::withSeatCount()
            ->with('course')
            ->when($request->query('course_id'), fn ($q, $v) => $q->where('course_id', $v))
            ->orderBy('course_id')
            ->orderBy('shift')
            ->orderBy('start_time')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $schedules->map(fn ($s) => (new ScheduleResource($s))->resolve())->values(),
        ]);
    }

    /** POST /api/admin/schedules  (JSON) */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'course_id'    => ['required', 'integer', 'exists:courses,id'],
            'teacher_name' => ['required', 'string', 'max:100'],
            'room_number'  => ['required', 'string', 'max:20'],
            'shift'        => ['required', 'in:morning,afternoon,evening'],
            'days'         => ['required', 'array', 'min:1', 'max:7'],
            'days.*'       => ['in:Mon,Tue,Wed,Thu,Fri,Sat,Sun', 'distinct'],
            'start_time'   => ['required', 'date_format:H:i'],
            'end_time'     => ['required', 'date_format:H:i'],
            'max_capacity' => ['required', 'integer', 'min:1', 'max:500'],
        ]);

        $this->assertTimesValid($data['start_time'], $data['end_time']);

        $schedule = Schedule::create($data);

        return response()->json([
            'success' => true,
            'message' => 'Schedule created.',
            'data'    => $this->resource($schedule->id),
        ], 201);
    }

    /** POST|PUT|PATCH /api/admin/schedules/{id}  (JSON, send only changed fields) */
    public function update(Request $request, int $id): JsonResponse
    {
        $schedule = Schedule::withSeatCount()->find($id);

        if (! $schedule) {
            $this->fail('Schedule not found.', 404);
        }

        $data = $request->validate([
            'course_id'    => ['sometimes', 'required', 'integer', 'exists:courses,id'],
            'teacher_name' => ['sometimes', 'required', 'string', 'max:100'],
            'room_number'  => ['sometimes', 'required', 'string', 'max:20'],
            'shift'        => ['sometimes', 'required', 'in:morning,afternoon,evening'],
            'days'         => ['sometimes', 'required', 'array', 'min:1', 'max:7'],
            'days.*'       => ['in:Mon,Tue,Wed,Thu,Fri,Sat,Sun', 'distinct'],
            'start_time'   => ['sometimes', 'required', 'date_format:H:i'],
            'end_time'     => ['sometimes', 'required', 'date_format:H:i'],
            'max_capacity' => ['sometimes', 'required', 'integer', 'min:1', 'max:500'],
        ]);

        $this->assertTimesValid(
            $data['start_time'] ?? substr($schedule->start_time, 0, 5),
            $data['end_time'] ?? substr($schedule->end_time, 0, 5)
        );

        if (isset($data['max_capacity']) && $data['max_capacity'] < $schedule->seatsTaken()) {
            $this->fail("Capacity cannot be lower than the {$schedule->seatsTaken()} seat(s) already taken.", 422);
        }

        $schedule->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Schedule updated.',
            'data'    => $this->resource($schedule->id),
        ]);
    }

    /**
     * DELETE /api/admin/schedules/{id}
     * Blocked when any enrollment (even dropped/rejected) points at it, because the
     * foreign key cascade would erase that student history.
     */
    public function destroy(int $id): JsonResponse
    {
        $schedule = Schedule::find($id);

        if (! $schedule) {
            $this->fail('Schedule not found.', 404);
        }

        if ($schedule->enrollments()->exists()) {
            $this->fail('This schedule has enrollment history and cannot be deleted. Lower its capacity or edit it instead.', 409);
        }

        $schedule->delete();

        return response()->json([
            'success' => true,
            'message' => 'Schedule deleted.',
        ]);
    }

    private function assertTimesValid(string $start, string $end): void
    {
        // "HH:MM" strings compare correctly as text.
        if ($end <= $start) {
            $this->fail('end_time must be later than start_time.', 422);
        }
    }

    private function resource(int $id): array
    {
        $schedule = Schedule::withSeatCount()->with('course')->findOrFail($id);

        return (new ScheduleResource($schedule))->resolve();
    }
}