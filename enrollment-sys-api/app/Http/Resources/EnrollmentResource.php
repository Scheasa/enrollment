<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Enrollment */
class EnrollmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'student_id'      => $this->student_id,
            'course_id'       => $this->course_id,
            'schedule_id'     => $this->schedule_id,
            'status'          => $this->status,
            'enrolled_date'   => $this->enrolled_date?->toDateString(),
            'remarks'         => $this->remarks,
            'created_at'      => $this->created_at?->toDateTimeString(),
            'student'         => new UserResource($this->whenLoaded('student')),
            'course'          => new CourseResource($this->whenLoaded('course')),
            'schedule'        => new ScheduleResource($this->whenLoaded('schedule')),
            'payments'        => PaymentResource::collection($this->whenLoaded('payments')),
            'payment_summary' => $this->when(
                $this->relationLoaded('payments') && $this->relationLoaded('course'),
                fn () => $this->paymentSummary()
            ),
        ];
    }
}