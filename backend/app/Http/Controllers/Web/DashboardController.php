<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Employee;
use App\Models\LeaveRequest;
use App\Models\WorkSchedule;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        $tz = WorkSchedule::current()?->timezone ?? config('app.timezone');
        $now = Carbon::now($tz);
        $today = $now->toDateString();

        $data = Cache::remember("dashboard:$today", 60, function () use ($now, $today) {
            $activeEmployees = Employee::where('is_active', true)->count();

            $todayAttendances = Attendance::whereDate('date', $today)->get();
            $present = $todayAttendances->whereNotNull('check_in_at');
            $late = $present->filter(fn ($a) => $a->late_minutes > 0 && $a->late_level !== 'green');

            $leaveToday = LeaveRequest::where('status', 'approved')
                ->whereDate('start_date', '<=', $today)
                ->whereDate('end_date', '>=', $today)
                ->selectRaw('type, count(*) as total')
                ->groupBy('type')
                ->pluck('total', 'type');

            $onLeave = (int) $leaveToday->sum();
            $notYet = max(0, $activeEmployees - $present->count() - $onLeave);

            $from = $now->copy()->subDays(29)->toDateString();
            $trendRaw = DB::table('attendances')
                ->whereBetween('date', [$from, $now->toDateString()])
                ->whereNotNull('check_in_at')
                ->selectRaw('DATE(date) as d, COUNT(*) as total')
                ->groupBy('d')
                ->pluck('total', 'd');

            $trend = [];
            for ($i = 29; $i >= 0; $i--) {
                $day = $now->copy()->subDays($i)->toDateString();
                $trend[] = ['date' => $day, 'total' => (int) ($trendRaw[$day] ?? 0)];
            }

            $perDepartment = DB::table('attendances')
                ->join('employees', 'employees.id', '=', 'attendances.employee_id')
                ->join('departments', 'departments.id', '=', 'employees.department_id')
                ->whereDate('attendances.date', $today)
                ->whereNotNull('attendances.check_in_at')
                ->selectRaw('departments.name as name, COUNT(*) as total')
                ->groupBy('departments.id', 'departments.name')
                ->get();

            $perLocation = DB::table('attendances')
                ->join('work_locations', 'work_locations.id', '=', 'attendances.location_id')
                ->whereDate('attendances.date', $today)
                ->whereNotNull('attendances.check_in_at')
                ->selectRaw('work_locations.name as name, COUNT(*) as total')
                ->groupBy('work_locations.id', 'work_locations.name')
                ->get();

            return [
                'active' => $activeEmployees,
                'hadir' => $present->count(),
                'telat' => $late->count(),
                'belum' => $notYet,
                'cuti' => (int) ($leaveToday['cuti'] ?? 0),
                'sakit' => (int) ($leaveToday['sakit'] ?? 0),
                'izin' => (int) ($leaveToday['izin'] ?? 0),
                'dinas' => (int) ($leaveToday['dinas'] ?? 0),
                'trend' => $trend,
                'perDepartment' => $perDepartment,
                'perLocation' => $perLocation,
            ];
        });

        return view('dashboard', compact('data'));
    }
}
