<?php

use App\Http\Controllers\Web\AccessController;
use App\Http\Controllers\Web\AuditLogController;
use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\DepartmentController;
use App\Http\Controllers\Web\DeviceController;
use App\Http\Controllers\Web\EmployeeController;
use App\Http\Controllers\Web\HolidayController;
use App\Http\Controllers\Web\LatenessRuleController;
use App\Http\Controllers\Web\LeaveBalanceController;
use App\Http\Controllers\Web\LeaveRequestController;
use App\Http\Controllers\Web\LocationController;
use App\Http\Controllers\Web\MenuController;
use App\Http\Controllers\Web\ScheduleController;
use App\Http\Controllers\Web\SettingController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect()->route('dashboard'));

Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login']);
});

Route::middleware(['auth', 'superadmin'])->group(function () {
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    Route::view('/dashboard', 'dashboard')->middleware('permission:dashboard.view')->name('dashboard');

    // Department
    Route::get('/departments', [DepartmentController::class, 'index'])->middleware('permission:departments.view')->name('departments.index');
    Route::get('/departments/create', [DepartmentController::class, 'create'])->middleware('permission:departments.create')->name('departments.create');
    Route::post('/departments', [DepartmentController::class, 'store'])->middleware('permission:departments.create')->name('departments.store');
    Route::get('/departments/{department}/edit', [DepartmentController::class, 'edit'])->middleware('permission:departments.update')->name('departments.edit');
    Route::put('/departments/{department}', [DepartmentController::class, 'update'])->middleware('permission:departments.update')->name('departments.update');
    Route::delete('/departments/{department}', [DepartmentController::class, 'destroy'])->middleware('permission:departments.delete')->name('departments.destroy');

    // Karyawan
    Route::get('/employees', [EmployeeController::class, 'index'])->middleware('permission:employees.view')->name('employees.index');
    Route::get('/employees/create', [EmployeeController::class, 'create'])->middleware('permission:employees.create')->name('employees.create');
    Route::post('/employees', [EmployeeController::class, 'store'])->middleware('permission:employees.create')->name('employees.store');
    Route::get('/employees/{employee}/edit', [EmployeeController::class, 'edit'])->middleware('permission:employees.update')->name('employees.edit');
    Route::put('/employees/{employee}', [EmployeeController::class, 'update'])->middleware('permission:employees.update')->name('employees.update');
    Route::delete('/employees/{employee}', [EmployeeController::class, 'destroy'])->middleware('permission:employees.delete')->name('employees.destroy');

    // Lokasi
    Route::get('/locations', [LocationController::class, 'index'])->middleware('permission:locations.view')->name('locations.index');
    Route::get('/locations/create', [LocationController::class, 'create'])->middleware('permission:locations.create')->name('locations.create');
    Route::post('/locations', [LocationController::class, 'store'])->middleware('permission:locations.create')->name('locations.store');
    Route::get('/locations/{location}/edit', [LocationController::class, 'edit'])->middleware('permission:locations.update')->name('locations.edit');
    Route::put('/locations/{location}', [LocationController::class, 'update'])->middleware('permission:locations.update')->name('locations.update');
    Route::delete('/locations/{location}', [LocationController::class, 'destroy'])->middleware('permission:locations.delete')->name('locations.destroy');

    // Jadwal kerja
    Route::get('/schedule', [ScheduleController::class, 'edit'])->middleware('permission:schedule.view')->name('schedule.index');
    Route::post('/schedule', [ScheduleController::class, 'update'])->middleware('permission:schedule.update')->name('schedule.update');

    // Keterlambatan
    Route::get('/lateness', [LatenessRuleController::class, 'edit'])->middleware('permission:lateness.view')->name('lateness.index');
    Route::post('/lateness', [LatenessRuleController::class, 'update'])->middleware('permission:lateness.update')->name('lateness.update');

    // Tanggal merah
    Route::get('/holidays', [HolidayController::class, 'index'])->middleware('permission:holidays.view')->name('holidays.index');
    Route::post('/holidays', [HolidayController::class, 'store'])->middleware('permission:holidays.create')->name('holidays.store');
    Route::delete('/holidays/{holiday}', [HolidayController::class, 'destroy'])->middleware('permission:holidays.delete')->name('holidays.destroy');

    // Jatah cuti
    Route::get('/leave-quota', [LeaveBalanceController::class, 'index'])->middleware('permission:leave_quota.view')->name('leave-quota.index');
    Route::post('/leave-quota', [LeaveBalanceController::class, 'update'])->middleware('permission:leave_quota.update')->name('leave-quota.update');

    // Pengaturan
    Route::get('/settings', [SettingController::class, 'edit'])->middleware('permission:settings.view')->name('settings.index');
    Route::post('/settings', [SettingController::class, 'update'])->middleware('permission:settings.update')->name('settings.update');

    // Audit log
    Route::get('/audit-logs', [AuditLogController::class, 'index'])->middleware('permission:audit_logs.view')->name('audit-logs.index');

    // Pengajuan (approval manager)
    Route::get('/leave-requests', [LeaveRequestController::class, 'index'])->middleware('permission:leave_requests.view')->name('leave-requests.index');
    Route::post('/leave-requests/{leaveRequest}/approve', [LeaveRequestController::class, 'approve'])->middleware('permission:leave_requests.approve')->name('leave-requests.approve');
    Route::post('/leave-requests/{leaveRequest}/reject', [LeaveRequestController::class, 'reject'])->middleware('permission:leave_requests.approve')->name('leave-requests.reject');

    // Device
    Route::get('/devices', [DeviceController::class, 'index'])->middleware('permission:devices.view')->name('devices.index');
    Route::delete('/devices/{device}', [DeviceController::class, 'destroy'])->middleware('permission:devices.update')->name('devices.destroy');

    // Manajemen akses & menu
    Route::get('/access', [AccessController::class, 'index'])->middleware('permission:access.view')->name('access.index');
    Route::post('/access', [AccessController::class, 'update'])->middleware('permission:access.update');
    Route::get('/menus', [MenuController::class, 'index'])->middleware('permission:menus.view')->name('menus.index');
    Route::post('/menus', [MenuController::class, 'update'])->middleware('permission:menus.update');
});
