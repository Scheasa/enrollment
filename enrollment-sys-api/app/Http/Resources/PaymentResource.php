<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Payment */
class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'enrollment_id'  => $this->enrollment_id,
            'amount'         => (float) $this->amount,
            'payment_method' => $this->payment_method,
            'receipt_image'  => $this->receipt_image,
            'receipt_url'    => $this->receipt_image
                ? asset('storage/' . $this->receipt_image)
                : null,
            'status'         => $this->status,
            'verified_by'    => $this->verified_by,
            'verifier_name'  => $this->whenLoaded('verifier', fn () => $this->verifier?->name),
            'paid_at'        => $this->paid_at?->toDateTimeString(),
            'created_at'     => $this->created_at?->toDateTimeString(),
            'enrollment'     => new EnrollmentResource($this->whenLoaded('enrollment')),
        ];
    }
}