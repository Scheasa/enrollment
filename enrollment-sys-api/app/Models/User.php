<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'role',
        'profile_image',
    ];

    protected $hidden = [
        'password',
    ];

    protected function casts(): array
    {
        return [
            // 'hashed' hashes the password automatically when it is assigned,
            // so never call Hash::make() before saving through this model.
            'password' => 'hashed',
        ];
    }

    // ---- Relationships ----

    /** Enrollments made by this user (when role = student). */
    public function enrollments(): HasMany
    {
        return $this->hasMany(Enrollment::class, 'student_id');
    }

    /** Payments this user verified (when role = staff/admin). */
    public function verifiedPayments(): HasMany
    {
        return $this->hasMany(Payment::class, 'verified_by');
    }

    // ---- Helpers ----

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isStaff(): bool
    {
        return in_array($this->role, ['staff', 'admin'], true);
    }
}