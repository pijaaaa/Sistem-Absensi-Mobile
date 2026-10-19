<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\Employee;
use App\Models\LeaveRequest;
use Carbon\Carbon;

class SummaryService
{
    public function __construct(
        private ScheduleService $schedule,
        private LeaveRequestService $leave,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function monthly(Employee $employee, int $year, int $month): array
    {
        $start = Carbon::create($year, $month, 1)->startOfMonth();
        $end = $start->copy()->endOfMonth();

        $attendances = $employee->attendances()
            ->whereBetween('date', [$start->toDateString(), $end->toDateString()])
            ->get();

        $present = $attendances->whereNotNull('check_in_at')->where('is_absent', false);
        $absents = $attendances->where('is_absent', true);

        $leaves = $employee->leaveRequests()
            ->where('status', 'approved')
            ->whereDate('start_date', '<=', $end)
            ->whereDate('end_date', '>=', $start)
            ->get();

        $lateCount = ['green' => 0, 'yellow' => 0, 'red' => 0];

        foreach ($present as $attendance) {
            if ($attendance->late_minutes <= 0) {
                continue;
            }

            $key = $attendance->late_level ?: 'green';

            if (isset($lateCount[$key])) {
                $lateCount[$key]++;
            }
        }

        $leaveDays = ['cuti' => 0, 'sakit' => 0, 'izin' => 0, 'dinas' => 0];

        foreach ($leaves as $leave) {
            $from = max($leave->start_date->day, 1);
            $to = min($leave->end_date->day, (int) $end->day);
            $leaveDays[$leave->type] += max(0, $to - $from + 1);
        }

        return [
            'year' => $year,
            'month' => $month,
            'hadir' => $present->count(),
            'telat' => [
                'toleransi' => $lateCount['green'],
                'kuning' => $lateCount['yellow'],
                'merah' => $lateCount['red'],
            ],
            'total_menit_telat' => (int) $present->sum('late_minutes'),
            'cuti' => $leaveDays['cuti'],
            'sakit' => $leaveDays['sakit'],
            'izin' => $leaveDays['izin'],
            'dinas' => $leaveDays['dinas'],
            'libur' => $this->nonWorkingDays($start, $end),
            'alfa' => $absents->count(),
            'sisa_cuti' => $this->leave->availableBalance($employee),
            'calendar' => $this->calendar($employee, $start, $end, $attendances, $leaves),
        ];
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    public function calendar(Employee $employee, Carbon $start, Carbon $end, $attendances, $leaves): array
    {
        $byDate = $attendances->keyBy(fn ($a) => $a->date->toDateString());
        $days = [];

        $cursor = $start->copy();

        while ($cursor->lessThanOrEqualTo($end)) {
            $key = $cursor->toDateString();
            $attendance = $byDate->get($key);
            $leave = $leaves->first(fn ($l) => $cursor->betweenIncluded($l->start_date, $l->end_date));

            $days[] = [
                'date' => $key,
                'status' => $this->dayStatus($cursor, $attendance, $leave),
            ];

            $cursor->addDay();
        }

        return $days;
    }

    private function dayStatus(Carbon $day, ?Attendance $attendance, ?LeaveRequest $leave): string
    {
        if ($attendance && $attendance->check_in_at) {
            return match (true) {
                $attendance->late_minutes <= 0, $attendance->late_level === 'green' => 'hadir',
                $attendance->late_level === 'yellow' => 'telat_kuning',
                default => 'telat_merah',
            };
        }

        if ($attendance && $attendance->is_absent) {
            return 'alfa';
        }

        if ($leave) {
            return $leave->type;
        }

        if (! $this->schedule->isWorkday($day)) {
            return 'libur';
        }

        return 'kosong';
    }

    private function nonWorkingDays(Carbon $start, Carbon $end): int
    {
        $count = 0;
        $cursor = $start->copy();

        while ($cursor->lessThanOrEqualTo($end)) {
            if (! $this->schedule->isWorkday($cursor)) {
                $count++;
            }
            $cursor->addDay();
        }

        return $count;
    }

    /**
     * @return array<string, mixed>
     */
    public function teamStats(Employee $manager, Carbon $day): array
    {
        $employeeIds = Employee::where('department_id', $manager->department_id)
            ->where('is_active', true)
            ->whereHas('user', fn ($q) => $q->where('role', 'karyawan'))
            ->pluck('id');

        $attendances = Attendance::whereIn('employee_id', $employeeIds)
            ->whereDate('date', $day->toDateString())
            ->get();

        $present = $attendances->whereNotNull('check_in_at');
        $late = $present->filter(fn ($a) => $a->late_minutes > 0 && $a->late_level !== 'green');
        $presentIds = $present->pluck('employee_id');

        return [
            'date' => $day->toDateString(),
            'is_workday' => $this->schedule->isWorkday($day),
            'total_karyawan' => $employeeIds->count(),
            'hadir' => $present->count(),
            'telat' => $late->count(),
            'belum_absen' => max(0, $employeeIds->count() - $presentIds->unique()->count()),
        ];
    }
}
