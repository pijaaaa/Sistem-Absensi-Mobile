<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DepartmentController;
use App\Http\Controllers\Api\FaceController;
use App\Http\Controllers\Api\MeController;
use Illuminate\Support\Facades\Route;

Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    Route::get('/me/menus', [MeController::class, 'menus']);
    Route::get('/me/permissions', [MeController::class, 'permissions']);

    Route::get('/departments', [DepartmentController::class, 'index'])
        ->middleware('permission:departments.view');

    Route::prefix('face')->group(function () {
        Route::post('/enroll', [FaceController::class, 'enroll']);
        Route::get('/template', [FaceController::class, 'show']);
        Route::post('/verify', [FaceController::class, 'verify']);
    });
});
