<?php

use App\Http\Controllers\Api\AttendanceApprovalController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\AttendanceSyncController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DepartmentController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\FaceController;
use App\Http\Controllers\Api\LeaveRequestController;
use App\Http\Controllers\Api\MeController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\SummaryController;
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

    Route::get('/devices', [DeviceController::class, 'index']);
    Route::post('/devices/register-backup', [DeviceController::class, 'registerBackup']);

    Route::post('/attendance/check-in', [AttendanceController::class, 'checkIn'])
        ->middleware('permission:attendance.create');
    Route::post('/attendance/check-out', [AttendanceController::class, 'checkOut'])
        ->middleware('permission:attendance.create');

    Route::get('/time', [AttendanceSyncController::class, 'serverTime']);
    Route::post('/attendance/sync', [AttendanceSyncController::class, 'sync'])
        ->middleware('permission:attendance.create');

    Route::get('/attendance-approval', [AttendanceApprovalController::class, 'index'])
        ->middleware('permission:attendance_approval.view');
    Route::post('/attendance-approval/{attendance}/approve', [AttendanceApprovalController::class, 'approve'])
        ->middleware('permission:attendance_approval.approve');
    Route::post('/attendance-approval/{attendance}/reject', [AttendanceApprovalController::class, 'reject'])
        ->middleware('permission:attendance_approval.approve');

    Route::post('/leave-requests', [LeaveRequestController::class, 'store'])
        ->middleware('permission:leave_requests.create');
    Route::get('/leave-requests', [LeaveRequestController::class, 'index'])
        ->middleware('permission:leave_requests.view');
    Route::get('/leave-balance', [LeaveRequestController::class, 'balance'])
        ->middleware('permission:leave_requests.view');
    Route::get('/leave-approval', [LeaveRequestController::class, 'inbox'])
        ->middleware('permission:leave_requests.approve');
    Route::post('/leave-approval/{leave}/approve', [LeaveRequestController::class, 'approve'])
        ->middleware('permission:leave_requests.approve');
    Route::post('/leave-approval/{leave}/reject', [LeaveRequestController::class, 'reject'])
        ->middleware('permission:leave_requests.approve');

    Route::get('/attendance/summary', [SummaryController::class, 'self'])
        ->middleware('permission:attendance.view');
    Route::get('/team-stats', [SummaryController::class, 'team'])
        ->middleware('permission:team_stats.view');

    Route::post('/push-tokens', [NotificationController::class, 'registerToken']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::post('/notifications/{notification}/read', [NotificationController::class, 'markRead']);
});
