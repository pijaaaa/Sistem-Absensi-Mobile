<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\Employee;
use App\Models\LeaveRequest;
use Carbon\Carbon;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

class ReportService
{
    /**
     * @param  array<string, mixed>  $filters
     */
    public function baseQuery(array $filters): Builder
    {
        return Employee::query()
            ->with(['department', 'workLocation', 'user'])
            ->where('is_active', true)
            ->when(! empty($filters['department_id']), fn ($q) => $q->where('department_id', $filters['department_id']))
            ->when(! empty($filters['location_id']), fn ($q) => $q->where('work_location_id', $filters['location_id']))
            ->orderBy('name');
    }

    /**
     * @param  array<string, mixed>  $filters
     */
    public function recap(array $filters, int $perPage = 25): LengthAwarePaginator
    {
        $paginator = $this->baseQuery($filters)->paginate($perPage)->withQueryString();
        $this->attachStats($paginator->getCollection(), $filters);

        return $paginator;
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return Collection<int, Employee>
     */
    public function all(array $filters): Collection
    {
        $employees = $this->baseQuery($filters)->get();
        $this->attachStats($employees, $filters);

        return $employees;
    }

    /**
     * @param  Collection<int, Employee>  $employees
     * @param  array<string, mixed>  $filters
     */
    private function attachStats(Collection $employees, array $filters): void
    {
        if ($employees->isEmpty()) {
            return;
        }

        [$from, $to] = $this->period($filters);
        $ids = $employees->pluck('id');

        $attendanceStats = Attendance::query()
            ->whereIn('employee_id', $ids)
            ->whereBetween('date', [$from->toDateString(), $to->toDateString()])
            ->selectRaw("employee_id,
                SUM(CASE WHEN check_in_at IS NOT NULL THEN 1 ELSE 0 END) as hadir,
                SUM(CASE WHEN is_absent = 1 THEN 1 ELSE 0 END) as alfa,
                SUM(late_minutes) as total_menit_telat,
                SUM(CASE WHEN late_minutes > 0 AND late_level <> 'green' THEN 1 ELSE 0 END) as telat")
            ->groupBy('employee_id')
            ->get()
            ->keyBy('employee_id');

        $leaves = LeaveRequest::query()
            ->whereIn('employee_id', $ids)
            ->where('status', 'approved')
            ->whereDate('start_date', '<=', $to)
            ->whereDate('end_date', '>=', $from)
            ->get()
            ->groupBy('employee_id');

        foreach ($employees as $employee) {
            $att = $attendanceStats->get($employee->id);
            $leaveDays = ['cuti' => 0, 'sakit' => 0, 'izin' => 0, 'dinas' => 0];

            foreach ($leaves->get($employee->id, collect()) as $leave) {
                $start = $leave->start_date->copy()->max($from);
                $end = $leave->end_date->copy()->min($to);
                $leaveDays[$leave->type] += (int) max(0, $start->diffInDays($end) + 1);
            }

            $employee->setAttribute('stats', [
                'hadir' => (int) ($att->hadir ?? 0),
                'telat' => (int) ($att->telat ?? 0),
                'total_menit_telat' => (int) ($att->total_menit_telat ?? 0),
                'alfa' => (int) ($att->alfa ?? 0),
                'cuti' => $leaveDays['cuti'],
                'sakit' => $leaveDays['sakit'],
                'izin' => $leaveDays['izin'],
                'dinas' => $leaveDays['dinas'],
            ]);
        }
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array{0: Carbon, 1: Carbon}
     */
    public function period(array $filters): array
    {
        $from = ! empty($filters['from'])
            ? Carbon::parse($filters['from'])->startOfDay()
            : Carbon::now()->startOfMonth();

        $to = ! empty($filters['to'])
            ? Carbon::parse($filters['to'])->endOfDay()
            : Carbon::now()->endOfDay();

        return [$from, $to];
    }
}
