<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class EnsureSuperadmin
{
    public function handle(Request $request, Closure $next): Response
    {
        if (! $request->user() || ! in_array($request->user()->role->value, ['superadmin', 'hr'], true)) {
            throw new AccessDeniedHttpException('Hanya superadmin atau HR yang boleh mengakses.');
        }

        return $next($request);
    }
}
