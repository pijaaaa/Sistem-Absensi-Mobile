<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class EnsurePermission
{
    /**
     * Periksa satu atau beberapa izin berformat "modul.aksi".
     * Semua izin yang diberikan wajib dimiliki.
     */
    public function handle(Request $request, Closure $next, string ...$keys): Response
    {
        foreach ($keys as $key) {
            if (! Gate::allows($key)) {
                throw new AccessDeniedHttpException("Tidak punya izin: $key");
            }
        }

        return $next($request);
    }
}
