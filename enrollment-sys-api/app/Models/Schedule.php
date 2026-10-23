<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Schedule extends Model
{
    protected $fillable = [
        'course_id',
        'teacher_name',
        'room_number',
        'shift',
        'days',
        'start_time',
        'end_time',
        'max_capacity',
    ];

    protected function casts(): array
    {
        return [
            'days'         => 'array',   // JSON column <-> PHP array
            'max_capacity' => 'integer',
        ];
    }

    // ---- Relationships ----

    public function course(): BelongsTo
    {
        return $this->belongsTo(Course::class);
    }

    public function enrollments(): HasMany
    {
        return $this->hasMany(Enrollment::class);
    }

    // ---- Scopes ----

    /**
     * Adds a `seats_taken` column to the query (one SQL query for the whole list,
     * instead of one per schedule). Pending and approved enrollments hold a seat.
     */
    public function scopeWithSeatCount(Builder $query): Builder
    {
        return $query->withCount([
            'enrollments as seats_taken' => fn ($q) => $q->whereIn('status', ['pending', 'approved']),
        ]);
    }

    // ---- Helpers ----

    public function seatsTaken(): int
    {
        // Use the preloaded count when scopeWithSeatCount() was applied.
        if (array_key_exists('seats_taken', $this->attributes)) {
            return (int) $this->attributes['seats_taken'];
        }

        return $this->enrollments()
            ->whereIn('status', ['pending', 'approved'])
            ->count();
    }

    public function seatsAvailable(): int
    {
        return max(0, $this->max_capacity - $this->seatsTaken());
    }

    public function isFull(): bool
    {
        return $this->seatsAvailable() === 0;
    }
}