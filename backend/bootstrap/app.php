<?php

use App\Http\Middleware\EnsureSuperadmin;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

$apiError = function (Request $request, int $status, string $message, array $errors = []) {
    if ($request->is('api/*') || $request->expectsJson()) {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors' => (object) $errors,
        ], $status);
    }

    return null;
};

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'superadmin' => EnsureSuperadmin::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) use ($apiError): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson()
        );

        $exceptions->render(fn (ValidationException $e, Request $request) => $apiError(
            $request, 422, 'Validasi gagal.', $e->errors()
        ));

        $exceptions->render(fn (AuthenticationException $e, Request $request) => $apiError(
            $request, 401, 'Tidak terautentikasi.'
        ));

        $exceptions->render(fn (AuthorizationException|AccessDeniedHttpException $e, Request $request) => $apiError(
            $request, 403, 'Akses ditolak.'
        ));

        $exceptions->render(fn (ModelNotFoundException|NotFoundHttpException $e, Request $request) => $apiError(
            $request, 404, 'Data tidak ditemukan.'
        ));

        $exceptions->render(fn (ThrottleRequestsException $e, Request $request) => $apiError(
            $request, 429, 'Terlalu banyak percobaan. Coba lagi nanti.'
        ));
    })->create();
