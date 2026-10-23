<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentResource;
use App\Models\Enrollment;
use App\Models\Payment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PaymentReviewController extends Controller
{
    use ApiResponses;

    private const WITH = ['enrollment.student', 'enrollment.course', 'verifier'];

    /**
     * GET /api/admin/payments
     * Filters: status, payment_method, enrollment_id, per_page, page
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'status'         => ['nullable', 'in:pending,verified,rejected'],
            'payment_method' => ['nullable', 'in:aba,acleda,wing,cash'],
            'enrollment_id'  => ['nullable', 'integer'],
            'per_page'       => ['nullable', 'integer'],
        ]);

        $page = Payment::with(self::WITH)
            ->when($request->query('status'), fn ($q, $v) => $q->where('status', $v))
            ->when($request->query('payment_method'), fn ($q, $v) => $q->where('payment_method', $v))
            ->when($request->query('enrollment_id'), fn ($q, $v) => $q->where('enrollment_id', $v))
            ->latest('id')
            ->paginate($this->perPage($request));

        return $this->paginated($page, fn ($p) => (new PaymentResource($p))->resolve());
    }

    /** GET /api/admin/payments/{id} */
    public function show(int $id): JsonResponse
    {
        $payment = Payment::with(self::WITH)->find($id);

        if (! $payment) {
            $this->fail('Payment not found.', 404);
        }

        return response()->json([
            'success' => true,
            'data'    => (new PaymentResource($payment))->resolve(),
        ]);
    }

    /**
     * POST /api/admin/payments/{id}/verify
     * Marks the payment verified (verified_by = the reviewer). If the enrollment is
     * still pending, it becomes approved.
     */
    public function verify(Request $request, int $id): JsonResponse
    {
        $admin = $request->user();

        DB::transaction(function () use ($id, $admin) {
            $payment = Payment::lockForUpdate()->find($id);

            if (! $payment) {
                $this->fail('Payment not found.', 404);
            }

            if ($payment->status !== 'pending') {
                $this->fail("This payment is already {$payment->status}.", 409);
            }

            $enrollment = Enrollment::lockForUpdate()->find($payment->enrollment_id);

            if (! in_array($enrollment->status, ['pending', 'approved'], true)) {
                $this->fail("Cannot verify: the enrollment is {$enrollment->status}.", 409);
            }

            $payment->update([
                'status'      => 'verified',
                'verified_by' => $admin->id,
                'paid_at'     => $payment->paid_at ?? now(),
            ]);

            if ($enrollment->status === 'pending') {
                $enrollment->update(['status' => 'approved']);
            }
        });

        return $this->respond($id, 'Payment verified.');
    }

    /**
     * POST /api/admin/payments/{id}/reject
     * Body: { "remarks": "reason" }   (required)
     * The payments table has no remarks column, so the reason is appended to the
     * enrollment's remarks, where the student can read it. The student may then upload a new receipt.
     */
    public function reject(Request $request, int $id): JsonResponse
    {
        $data  = $request->validate(['remarks' => ['required', 'string', 'max:500']]);
        $admin = $request->user();

        DB::transaction(function () use ($id, $data, $admin) {
            $payment = Payment::lockForUpdate()->find($id);

            if (! $payment) {
                $this->fail('Payment not found.', 404);
            }

            if ($payment->status !== 'pending') {
                $this->fail("This payment is already {$payment->status}.", 409);
            }

            $payment->update([
                'status'      => 'rejected',
                'verified_by' => $admin->id,
            ]);

            $enrollment = Enrollment::lockForUpdate()->find($payment->enrollment_id);
            $note       = "[Payment #{$payment->id} rejected] {$data['remarks']}";

            $enrollment->update([
                'remarks' => $enrollment->remarks ? $enrollment->remarks . "\n" . $note : $note,
            ]);
        });

        return $this->respond($id, 'Payment rejected.');
    }

    private function respond(int $id, string $message): JsonResponse
    {
        $payment = Payment::with(self::WITH)->findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => (new PaymentResource($payment))->resolve(),
        ]);
    }
}