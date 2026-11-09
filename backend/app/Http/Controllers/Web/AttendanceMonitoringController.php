<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Department;
use App\Models\Employee;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AttendanceMonitoringController extends Controller
{
    public function index(Request $request): View
    {
        $date = Carbon::parse($request->input('date', now()->toDateString()))->toDateString();
        $departmentId = $request->integer('department_id') ?: null;
        $employees = Employee::with(['user', 'department', 'workLocation'])
            ->where('is_active', true)
            ->when($departmentId, fn ($query) => $query->where('department_id', $departmentId))
            ->orderBy('name')
            ->get();
        $attendances = Attendance::whereDate('date', $date)->get()->keyBy('employee_id');
        $departmentSummaries = $employees->groupBy('department_id')->map(function ($departmentEmployees) use ($attendances) {
            return [
                'department' => $departmentEmployees->first()->department?->name ?? 'Tanpa department',
                'total' => $departmentEmployees->count(),
                'present' => $departmentEmployees->filter(fn ($employee) => $attendances->get($employee->id)?->check_in_at)->count(),
                'missing' => $departmentEmployees->filter(fn ($employee) => ! $attendances->get($employee->id)?->check_in_at)->values(),
            ];
        })->values();

        return view('attendance-monitoring.index', [
            'date' => $date,
            'employees' => $employees,
            'attendances' => $attendances,
            'departments' => Department::orderBy('name')->get(),
            'departmentId' => $departmentId,
            'departmentSummaries' => $departmentSummaries,
        ]);
    }
}
