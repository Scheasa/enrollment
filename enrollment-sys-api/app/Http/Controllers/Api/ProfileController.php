<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class ProfileController extends Controller
{
    /**
     * GET /api/me   (requires X-User-Id header)
     * Handy for Flutter to refresh the stored user, and for testing the middleware.
     */
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => (new UserResource($request->user()))->resolve(),
        ]);
    }

    /**
     * POST|PUT|PATCH /api/me   (use POST when uploading a photo)
     * Fields (all optional): name, phone, image (file), remove_image (1)
     * Email and role cannot be changed here.
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'name'         => ['sometimes', 'required', 'string', 'max:100'],
            'phone'        => ['sometimes', 'nullable', 'string', 'max:20'],
            'image'        => ['sometimes', 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'remove_image' => ['sometimes', 'boolean'],
        ]);

        $user->fill(Arr::only($data, ['name', 'phone']));

        if ($request->hasFile('image')) {
            $this->deleteImage($user->profile_image);
            $user->profile_image = $request->file('image')->store('profiles', 'public');
        } elseif ($request->boolean('remove_image')) {
            $this->deleteImage($user->profile_image);
            $user->profile_image = null;
        }

        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profile updated.',
            'data'    => (new UserResource($user->fresh()))->resolve(),
        ]);
    }

    /**
     * POST /api/me/password
     * Body: { current_password, password, password_confirmation }
     */
    public function changePassword(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'password'         => ['required', 'string', 'min:6', 'max:100', 'confirmed', 'different:current_password'],
        ]);

        if (! Hash::check($data['current_password'], $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => 'Your current password is incorrect.',
            ]);
        }

        $user->password = $data['password'];   // hashed by the model cast, never Hash::make here
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Password changed.',
        ]);
    }

    private function deleteImage(?string $path): void
    {
        if ($path) {
            Storage::disk('public')->delete($path);
        }
    }
}