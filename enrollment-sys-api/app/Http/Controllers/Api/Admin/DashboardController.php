<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentResource;
use App\Models\Course;
use App\Models\Enrollment;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /** GET /api/admin/dashboard */
    public function index(): JsonResponse
    {
        $enrollments = array_merge(
            ['pending' => 0, 'approved' => 0, 'rejected' => 0, 'dropped' => 0],
            Enrollment::select('status', DB::raw('count(*) as total'))
                ->groupBy('status')->pluck('total', 'status')->map(fn ($n) => (int) $n)->all()
        );

        $payments = array_merge(
            ['pending' => 0, 'verified' => 0, 'rejected' => 0],
            Payment::select('status', DB::raw('count(*) as total'))
                ->groupBy('status')->pluck('total', 'status')->map(fn ($n) => (int) $n)->all()
        );

        $recentPending = Payment::where('status', 'pending')
            ->with(['enrollment.student', 'enrollment.course'])
            ->latest('id')
            ->limit(5)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'total_students'          => User::where('role', 'student')->count(),
                'active_courses'          => Course::active()->count(),
                'enrollments'             => $enrollments,
                'payments'                => $payments,
                'revenue_total'           => (float) Payment::where('status', 'verified')->sum('amount'),
                'revenue_this_month'      => (float) Payment::where('status', 'verified')
                    ->whereYear('paid_at', now()->year)
                    ->whereMonth('paid_at', now()->month)
                    ->sum('amount'),
                'recent_pending_payments' => $recentPending
                    ->map(fn ($p) => (new PaymentResource($p))->resolve())
                    ->values(),
            ],
        ]);
    }
}