<?php

use App\Http\Controllers\Web\AccessController;
use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\MenuController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect()->route('dashboard'));

Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login']);
});

Route::middleware(['auth', 'superadmin'])->group(function () {
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    Route::view('/dashboard', 'dashboard')
        ->middleware('permission:dashboard.view')
        ->name('dashboard');

    Route::get('/access', [AccessController::class, 'index'])
        ->middleware('permission:access.view')->name('access.index');
    Route::post('/access', [AccessController::class, 'update'])
        ->middleware('permission:access.update');

    Route::get('/menus', [MenuController::class, 'index'])
        ->middleware('permission:menus.view')->name('menus.index');
    Route::post('/menus', [MenuController::class, 'update'])
        ->middleware('permission:menus.update');
});
