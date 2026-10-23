<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Schedule */
class ScheduleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'course_id'       => $this->course_id,
            'teacher_name'    => $this->teacher_name,
            'room_number'     => $this->room_number,
            'shift'           => $this->shift,
            'days'            => $this->days,                       // ["Mon","Wed","Fri"]
            'start_time'      => substr($this->start_time, 0, 5),   // "07:30"
            'end_time'        => substr($this->end_time, 0, 5),
            'max_capacity'    => $this->max_capacity,
            'seats_taken'     => $this->seatsTaken(),
            'seats_available' => $this->seatsAvailable(),
            'is_full'         => $this->isFull(),
            'course'          => new CourseResource($this->whenLoaded('course')),
        ];
    }
}