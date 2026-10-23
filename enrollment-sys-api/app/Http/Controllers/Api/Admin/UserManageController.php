<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

/** Admin-only: list, create, edit and delete users. */
class UserManageController extends Controller
{
    use ApiResponses;

    /** GET /api/admin/users?role=staff&search=sok&per_page=20 */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'role'     => ['nullable', 'in:student,staff,admin'],
            'search'   => ['nullable', 'string', 'max:100'],
            'per_page' => ['nullable', 'integer'],
        ]);

        $page = User::query()
            ->when($request->query('role'), fn ($q, $v) => $q->where('role', $v))
            ->when($request->query('search'), fn ($q, $s) => $q->where(fn ($w) => $w
                ->where('name', 'like', "%{$s}%")
                ->orWhere('email', 'like', "%{$s}%")))
            ->orderBy('id')
            ->paginate($this->perPage($request));

        return $this->paginated($page, fn ($u) => (new UserResource($u))->resolve());
    }

    /** POST /api/admin/users */
    public function store(Request $request): JsonResponse
    {
        $request->merge(['email' => strtolower(trim((string) $request->input('email')))]);

        $data = $request->validate([
            'name'     => ['required', 'string', 'max:100'],
            'email'    => ['required', 'email', 'max:150', 'unique:users,email'],
            'phone'    => ['nullable', 'string', 'max:20'],
            'password' => ['required', 'string', 'min:6', 'max:100'],
            'role'     => ['required', 'in:student,staff,admin'],
        ]);

        $user = User::create($data);   // password is hashed by the model cast

        return response()->json([
            'success' => true,
            'message' => 'User created.',
            'data'    => (new UserResource($user))->resolve(),
        ], 201);
    }

    /**
     * POST|PUT|PATCH /api/admin/users/{id}
     * Send only the fields to change. A non-empty "password" resets the password
     * and signs that user out of every device.
     *
     * Because an admin can never change their own role or delete themselves,
     * at least one admin always remains.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = User::find($id);

        if (! $user) {
            $this->fail('User not found.', 404);
        }

        if ($request->has('email')) {
            $request->merge(['email' => strtolower(trim((string) $request->input('email')))]);
        }

        $data = $request->validate([
            'name'     => ['sometimes', 'required', 'string', 'max:100'],
            'email'    => ['sometimes', 'required', 'email', 'max:150', Rule::unique('users', 'email')->ignore($user->id)],
            'phone'    => ['sometimes', 'nullable', 'string', 'max:20'],
            'role'     => ['sometimes', 'required', 'in:student,staff,admin'],
            'password' => ['sometimes', 'nullable', 'string', 'min:6', 'max:100'],
        ]);

        $isSelf = $user->id === $request->user()->id;

        if ($isSelf && isset($data['role']) && $data['role'] !== $user->role) {
            $this->fail('You cannot change your own role.', 409);
        }

        $passwordChanged = ! empty($data['password']);

        if (! $passwordChanged) {
            unset($data['password']);
        }

        $user->update($data);   // password is hashed by the model cast

        // Sign the user out everywhere after a password reset (not the admin themself).
        if ($passwordChanged && ! $isSelf) {
            $user->tokens()->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'User updated.',
            'data'    => (new UserResource($user->fresh()))->resolve(),
        ]);
    }

    /** DELETE /api/admin/users/{id} */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = User::find($id);

        if (! $user) {
            $this->fail('User not found.', 404);
        }

        if ($user->id === $request->user()->id) {
            $this->fail('You cannot delete your own account.', 409);
        }

        // Deleting would also wipe their enrollments and payments (database cascade).
        if ($user->enrollments()->exists()) {
            $this->fail('This user has enrollment history and cannot be deleted.', 409);
        }

        if ($user->profile_image) {
            Storage::disk('public')->delete($user->profile_image);
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'User deleted.',
        ]);
    }
}