<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ScheduleResource;
use App\Models\Schedule;
use Illuminate\Http\JsonResponse;

class ScheduleController extends Controller
{
    /**
     * GET /api/schedules/{id}
     * One schedule with its course and live seat availability.
     */
    public function show(int $id): JsonResponse
    {
        $schedule = Schedule::withSeatCount()
            ->with('course')
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => (new ScheduleResource($schedule))->resolve(),
        ]);
    }
}