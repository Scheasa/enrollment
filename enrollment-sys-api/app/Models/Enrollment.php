<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Enrollment extends Model
{
    protected $fillable = [
        'student_id',
        'course_id',
        'schedule_id',
        'status',
        'enrolled_date',
        'remarks',
    ];

    protected function casts(): array
    {
        return [
            'enrolled_date' => 'date:Y-m-d',
        ];
    }

    // ---- Relationships ----

    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function course(): BelongsTo
    {
        return $this->belongsTo(Course::class);
    }

    public function schedule(): BelongsTo
    {
        return $this->belongsTo(Schedule::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    // ---- Helpers ----

    /**
     * Money summary for this enrollment. Needs the `course` and `payments`
     * relations to be loaded (the API resource only calls it when they are).
     *
     *  fee       = course fee
     *  verified  = payments an admin has approved
     *  pending   = payments uploaded but not reviewed yet
     *  remaining = fee - verified - pending (what the student can still pay)
     */
    public function paymentSummary(): array
    {
        $fee      = (float) ($this->course->fee ?? 0);
        $verified = (float) $this->payments->where('status', 'verified')->sum('amount');
        $pending  = (float) $this->payments->where('status', 'pending')->sum('amount');

        return [
            'fee'           => round($fee, 2),
            'verified'      => round($verified, 2),
            'pending'       => round($pending, 2),
            'remaining'     => max(0, round($fee - $verified - $pending, 2)),
            'is_fully_paid' => $fee > 0 && $verified >= $fee,
        ];
    }
}