<?php

namespace App\Http\Controllers\Api\Concerns;

use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\JsonResponse;
use Illuminate\Pagination\LengthAwarePaginator;

trait ApiResponses
{
    /** Stop the request and answer with a JSON error (rolls back any open transaction). */
    protected function fail(string $message, int $status): never
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $message,
        ], $status));
    }

    /** Standard paginated list: { success, data: [...], meta: {...} } */
    protected function paginated(LengthAwarePaginator $page, callable $map): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $page->getCollection()->map($map)->values(),
            'meta'    => [
                'current_page' => $page->currentPage(),
                'last_page'    => $page->lastPage(),
                'per_page'     => $page->perPage(),
                'total'        => $page->total(),
            ],
        ]);
    }

    protected function perPage(\Illuminate\Http\Request $request): int
    {
        return min(max((int) $request->query('per_page', 20), 1), 100);
    }
}