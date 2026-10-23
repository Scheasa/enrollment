<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Resources\EnrollmentResource;
use App\Models\Enrollment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EnrollmentReviewController extends Controller
{
    use ApiResponses;

    private const WITH = ['student', 'course', 'schedule', 'payments'];

    /**
     * GET /api/admin/enrollments
     * Filters: status, course_id, search (student name/email), per_page, page
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'status'    => ['nullable', 'in:pending,approved,rejected,dropped'],
            'course_id' => ['nullable', 'integer'],
            'search'    => ['nullable', 'string', 'max:100'],
            'per_page'  => ['nullable', 'integer'],
        ]);

        $page = Enrollment::with(self::WITH)
            ->when($request->query('status'), fn ($q, $v) => $q->where('status', $v))
            ->when($request->query('course_id'), fn ($q, $v) => $q->where('course_id', $v))
            ->when($request->query('search'), fn ($q, $s) => $q->whereHas('student', fn ($sq) => $sq
                ->where('name', 'like', "%{$s}%")
                ->orWhere('email', 'like', "%{$s}%")))
            ->latest('id')
            ->paginate($this->perPage($request));

        return $this->paginated($page, fn ($e) => (new EnrollmentResource($e))->resolve());
    }

    /** GET /api/admin/enrollments/{id} */
    public function show(int $id): JsonResponse
    {
        $enrollment = Enrollment::with(self::WITH)->find($id);

        if (! $enrollment) {
            $this->fail('Enrollment not found.', 404);
        }

        return response()->json([
            'success' => true,
            'data'    => (new EnrollmentResource($enrollment))->resolve(),
        ]);
    }

    /**
     * POST /api/admin/enrollments/{id}/approve
     * Body (optional): { "remarks": "..." }
     * Only a pending enrollment can be approved.
     */
    public function approve(Request $request, int $id): JsonResponse
    {
        $data = $request->validate(['remarks' => ['nullable', 'string', 'max:500']]);

        DB::transaction(function () use ($id, $data) {
            $enrollment = Enrollment::lockForUpdate()->find($id);

            if (! $enrollment) {
                $this->fail('Enrollment not found.', 404);
            }

            if ($enrollment->status !== 'pending') {
                $this->fail("Only a pending enrollment can be approved (this one is {$enrollment->status}).", 409);
            }

            $enrollment->update([
                'status'  => 'approved',
                'remarks' => $data['remarks'] ?? $enrollment->remarks,
            ]);
        });

        return $this->respond($id, 'Enrollment approved.');
    }

    /**
     * POST /api/admin/enrollments/{id}/reject
     * Body: { "remarks": "reason shown to the student" }   (required)
     * Pending or approved enrollments can be rejected. Any payments still waiting
     * for review are rejected too. Verified payments are left alone (refunds are manual).
     */
    public function reject(Request $request, int $id): JsonResponse
    {
        $data  = $request->validate(['remarks' => ['required', 'string', 'max:500']]);
        $admin = $request->user();

        DB::transaction(function () use ($id, $data, $admin) {
            $enrollment = Enrollment::lockForUpdate()->find($id);

            if (! $enrollment) {
                $this->fail('Enrollment not found.', 404);
            }

            if (! in_array($enrollment->status, ['pending', 'approved'], true)) {
                $this->fail("An enrollment that is {$enrollment->status} cannot be rejected.", 409);
            }

            $enrollment->update([
                'status'  => 'rejected',
                'remarks' => $data['remarks'],
            ]);

            $enrollment->payments()
                ->where('status', 'pending')
                ->update(['status' => 'rejected', 'verified_by' => $admin->id]);
        });

        return $this->respond($id, 'Enrollment rejected.');
    }

    private function respond(int $id, string $message): JsonResponse
    {
        $enrollment = Enrollment::with(self::WITH)->findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => (new EnrollmentResource($enrollment))->resolve(),
        ]);
    }
}