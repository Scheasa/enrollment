<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Course */
class CourseResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'title'           => $this->title,
            'description'     => $this->description,
            'category'        => $this->category,
            'level'           => $this->level,
            'fee'             => (float) $this->fee,
            'duration_months' => $this->duration_months,
            'thumbnail_image' => $this->thumbnail_image,
            'thumbnail_url'   => $this->thumbnail_image
                ? asset('storage/' . $this->thumbnail_image)
                : null,
            'is_active'       => $this->is_active,
            'schedules_count' => $this->whenCounted('schedules'),
            'schedules'       => ScheduleResource::collection($this->whenLoaded('schedules')),
        ];
    }
}