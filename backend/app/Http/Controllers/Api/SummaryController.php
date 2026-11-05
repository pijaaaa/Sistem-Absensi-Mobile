<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WorkSchedule;
use App\Services\SummaryService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SummaryController extends Controller
{
    public function __construct(private SummaryService $summary) {}

    public function self(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Profil karyawan tidak ditemukan.', 'errors' => (object) []], 422);
        }

        $year = (int) $request->input('year', now()->year);
        $month = (int) $request->input('month', now()->month);

        if ($month < 1 || $month > 12) {
            return response()->json(['success' => false, 'message' => 'Bulan tidak valid.', 'errors' => (object) []], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $this->summary->monthly($employee, $year, $month),
        ]);
    }

    public function team(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Profil karyawan tidak ditemukan.', 'errors' => (object) []], 422);
        }

        $day = Carbon::now(WorkSchedule::current()?->timezone ?? config('app.timezone'));

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $this->summary->teamStats($employee, $day),
        ]);
    }

    public function logs(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;
        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Profil karyawan tidak ditemukan.', 'errors' => (object) []], 422);
        }

        $attendances = $employee->attendances()
            ->orderBy('date', 'desc')
            ->limit(10)
            ->get();

        $items = [];
        foreach ($attendances as $att) {
            if ($att->check_out_at) {
                $items[] = [
                    'date' => $att->date?->format('d M Y') ?? (is_string($att->date) ? $att->date : now()->format('d M Y')),
                    'status' => 'Pulang',
                    'time' => $att->check_out_at?->format('H:i') ?? '',
                    'type' => 'present',
                    'is_checkout' => true,
                ];
            }
            if ($att->check_in_at) {
                $isLate = ($att->late_minutes ?? 0) > 0;
                $items[] = [
                    'date' => $att->date?->format('d M Y') ?? (is_string($att->date) ? $att->date : now()->format('d M Y')),
                    'status' => $isLate ? "Telat {$att->late_minutes}m" : 'Masuk',
                    'time' => $att->check_in_at?->format('H:i') ?? '',
                    'type' => $isLate ? 'lateYellow' : 'present',
                    'is_checkout' => false,
                ];
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $items,
        ]);
    }

    public function teamAttendanceDetail(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Profil karyawan tidak ditemukan.', 'errors' => (object) []], 422);
        }

        $date = $request->input('date', now()->toDateString());
        $search = $request->input('search');

        $employeesQuery = \App\Models\Employee::where('department_id', $employee->department_id)
            ->where('is_active', true)
            ->whereHas('user', fn ($q) => $q->where('role', 'karyawan'));

        if ($search) {
            $employeesQuery->where('name', 'like', "%{$search}%");
        }

        $employees = $employeesQuery->orderBy('name')->get();

        $attendances = \App\Models\Attendance::whereIn('employee_id', $employees->pluck('id'))
            ->whereDate('date', $date)
            ->with(['location', 'employee'])
            ->get()
            ->keyBy('employee_id');

        $result = [];
        foreach ($employees as $emp) {
            $att = $attendances->get($emp->id);

            $result[] = [
                'employee_id' => $emp->id,
                'name' => $emp->name,
                'check_in_at' => $att?->check_in_at?->format('H:i:s'),
                'check_out_at' => $att?->check_out_at?->format('H:i:s'),
                'in_lat' => $att?->in_lat,
                'in_lng' => $att?->in_lng,
                'out_lat' => $att?->out_lat,
                'out_lng' => $att?->out_lng,
                'location_name' => $att?->location?->name,
                'is_backup_device' => $att?->is_backup_device ?? false,
                'late_minutes' => $att?->late_minutes ?? 0,
                'approval_status' => $att?->approval_status,
            ];
        }

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => [
                'date' => $date,
                'employees' => $result,
            ],
        ]);
    }
}
