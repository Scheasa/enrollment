<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Token-less "login check" for this project.
 *
 * Flutter stores user_id after login and sends it on every protected request:
 *     X-User-Id: 3
 * (a `user_id` field in the body/query also works, handy for multipart uploads).
 *
 * After this middleware runs, $request->user() returns the User model.
 *
 * NOTE: this trusts the client. Anyone who knows an id can send it. Acceptable for
 * a university project, but it is not real security (that is what tokens are for).
 */
class IdentifyUser
{
    public function handle(Request $request, Closure $next): Response
    {
        $userId = $request->header('X-User-Id') ?? $request->input('user_id');

        if (! $userId || ! ctype_digit((string) $userId)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated. Send the X-User-Id header.',
            ], 401);
        }

        $user = User::find((int) $userId);

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated. User not found.',
            ], 401);
        }

        $request->setUserResolver(fn () => $user);

        return $next($request);
    }
}