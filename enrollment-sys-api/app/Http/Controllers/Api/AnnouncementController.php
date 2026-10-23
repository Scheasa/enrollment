<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AnnouncementResource;
use App\Models\Announcement;
use Illuminate\Http\JsonResponse;

class AnnouncementController extends Controller
{
    /** GET /api/announcements  (active only, newest first) */
    public function index(): JsonResponse
    {
        $items = Announcement::active()->latest()->get();

        return response()->json([
            'success' => true,
            'data'    => $items->map(fn ($a) => (new AnnouncementResource($a))->resolve())->values(),
        ]);
    }

    /** GET /api/announcements/{id} */
    public function show(int $id): JsonResponse
    {
        $item = Announcement::active()->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => (new AnnouncementResource($item))->resolve(),
        ]);
    }
}