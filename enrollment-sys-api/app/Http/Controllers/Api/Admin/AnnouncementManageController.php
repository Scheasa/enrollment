<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Resources\AnnouncementResource;
use App\Models\Announcement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AnnouncementManageController extends Controller
{
    use ApiResponses;

    /** GET /api/admin/announcements  (including hidden ones) */
    public function index(): JsonResponse
    {
        $items = Announcement::latest('id')->get();

        return response()->json([
            'success' => true,
            'data'    => $items->map(fn ($a) => (new AnnouncementResource($a))->resolve())->values(),
        ]);
    }

    /** POST /api/admin/announcements  (JSON, or multipart with an image) */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title'     => ['required', 'string', 'max:200'],
            'content'   => ['required', 'string', 'max:10000'],
            'image'     => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        unset($data['image']);

        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image')->store('announcements', 'public');
        }

        $item = Announcement::create($data)->refresh();

        return response()->json([
            'success' => true,
            'message' => 'Announcement created.',
            'data'    => (new AnnouncementResource($item))->resolve(),
        ], 201);
    }

    /** POST|PUT|PATCH /api/admin/announcements/{id}  (use POST when uploading an image) */
    public function update(Request $request, int $id): JsonResponse
    {
        $item = Announcement::find($id);

        if (! $item) {
            $this->fail('Announcement not found.', 404);
        }

        $data = $request->validate([
            'title'     => ['sometimes', 'required', 'string', 'max:200'],
            'content'   => ['sometimes', 'required', 'string', 'max:10000'],
            'image'     => ['sometimes', 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'is_active' => ['sometimes', 'required', 'boolean'],
        ]);

        unset($data['image']);

        if ($request->hasFile('image')) {
            if ($item->image) {
                Storage::disk('public')->delete($item->image);
            }
            $data['image'] = $request->file('image')->store('announcements', 'public');
        }

        $item->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Announcement updated.',
            'data'    => (new AnnouncementResource($item->fresh()))->resolve(),
        ]);
    }

    /** DELETE /api/admin/announcements/{id} */
    public function destroy(int $id): JsonResponse
    {
        $item = Announcement::find($id);

        if (! $item) {
            $this->fail('Announcement not found.', 404);
        }

        if ($item->image) {
            Storage::disk('public')->delete($item->image);
        }

        $item->delete();

        return response()->json([
            'success' => true,
            'message' => 'Announcement deleted.',
        ]);
    }
}