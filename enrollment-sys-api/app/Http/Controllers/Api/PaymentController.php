<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentResource;
use App\Models\Enrollment;
use App\Models\Payment;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class PaymentController extends Controller
{
    /** Relations returned with every payment. */
    private const WITH = ['enrollment.course', 'verifier'];

    /**
     * GET /api/payments
     * The logged-in student's own payments. Optional: ?status=pending|verified|rejected
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'status' => ['nullable', 'in:pending,verified,rejected'],
        ]);

        $payments = Payment::whereHas('enrollment', fn ($q) => $q->where('student_id', $request->user()->id))
            ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
            ->with(self::WITH)
            ->latest('id')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $payments->map(fn ($p) => (new PaymentResource($p))->resolve())->values(),
        ]);
    }

    /**
     * GET /api/payments/{id}
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $payment = Payment::whereHas('enrollment', fn ($q) => $q->where('student_id', $request->user()->id))
            ->with(self::WITH)
            ->find($id);

        if (! $payment) {
            $this->fail('Payment not found.', 404);
        }

        return response()->json([
            'success' => true,
            'data'    => (new PaymentResource($payment))->resolve(),
        ]);
    }

    /**
     * POST /api/payments        (multipart/form-data)
     *
     * Fields:
     *   enrollment_id   required
     *   amount          required, USD, must not exceed the remaining balance
     *   payment_method  required: aba | acleda | wing | cash
     *   receipt_image   required for aba/acleda/wing (jpg, png, webp, max 5 MB); optional for cash
     *   paid_at         optional date/time of the transfer (defaults to now)
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'enrollment_id'  => ['required', 'integer'],
            'amount'         => ['required', 'numeric', 'gt:0', 'max:99999'],
            'payment_method' => ['required', Rule::in(['aba', 'acleda', 'wing', 'cash'])],
            'receipt_image'  => ['required_unless:payment_method,cash', 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'paid_at'        => ['nullable', 'date'],
        ]);

        $payment = DB::transaction(function () use ($request, $user, $data) {
            // Lock the enrollment row so a double-tap cannot create two pending payments.
            $enrollment = Enrollment::with('course')
                ->where('student_id', $user->id)
                ->lockForUpdate()
                ->find($data['enrollment_id']);

            if (! $enrollment) {
                $this->fail('Enrollment not found.', 404);
            }

            if (! in_array($enrollment->status, ['pending', 'approved'], true)) {
                $this->fail("You cannot pay for an enrollment that is {$enrollment->status}.", 409);
            }

            // Pending + verified payments both count against the course fee.
            $committed = (float) $enrollment->payments()
                ->whereIn('status', ['pending', 'verified'])
                ->sum('amount');
            $remaining = round((float) $enrollment->course->fee - $committed, 2);

            if ($remaining <= 0) {
                $this->fail('This enrollment is already fully paid.', 409);
            }

            if ($enrollment->payments()->where('status', 'pending')->exists()) {
                $this->fail('You already have a payment waiting for review. Please wait for the admin.', 409);
            }

            $amount = round((float) $data['amount'], 2);

            if ($amount > $remaining) {
                $this->fail('Amount exceeds the remaining balance of $' . number_format($remaining, 2) . '.', 422);
            }

            $path = $request->hasFile('receipt_image')
                ? $request->file('receipt_image')->store('receipts', 'public')
                : null;

            return Payment::create([
                'enrollment_id'  => $enrollment->id,
                'amount'         => $amount,
                'payment_method' => $data['payment_method'],
                'receipt_image'  => $path,
                'status'         => 'pending',
                'paid_at'        => isset($data['paid_at']) ? Carbon::parse($data['paid_at']) : now(),
            ]);
        });

        $payment->load(self::WITH);

        return response()->json([
            'success' => true,
            'message' => 'Receipt uploaded. Waiting for admin review.',
            'data'    => (new PaymentResource($payment))->resolve(),
        ], 201);
    }

    /** Stop the request and answer with a JSON error (rolls back any open transaction). */
    private function fail(string $message, int $status): never
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $message,
        ], $status));
    }
}