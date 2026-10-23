<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Announcement */
class AnnouncementResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'title'      => $this->title,
            'content'    => $this->content,
            'image'      => $this->image,
            'image_url'  => $this->image ? asset('storage/' . $this->image) : null,
            'is_active'  => $this->is_active,
            'created_at' => $this->created_at?->toDateTimeString(),
        ];
    }
}