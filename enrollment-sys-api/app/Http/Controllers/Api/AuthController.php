<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * POST /api/auth/register
     * Public sign-up always creates a "student". Staff/admin accounts are made by an admin.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'phone'    => $request->phone,
            'password' => $request->password,   // hashed by the model cast
            'role'     => 'student',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Registration successful.',
            'token'   => $user->createToken('flutter-app')->plainTextToken,
            'user_id' => $user->id,
            'user'    => (new UserResource($user))->resolve(),
        ], 201);
    }

    /**
     * POST /api/auth/login
     * Returns a Sanctum token. Flutter sends it as: Authorization: Bearer <token>
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid email or password.',
            ], 401);
        }

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'token'   => $user->createToken('flutter-app')->plainTextToken,
            'user_id' => $user->id,
            'user'    => (new UserResource($user))->resolve(),
        ]);
    }

    /**
     * POST /api/auth/logout  (needs the Bearer token)
     * Deletes only the token used for this request.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out.',
        ]);
    }
}