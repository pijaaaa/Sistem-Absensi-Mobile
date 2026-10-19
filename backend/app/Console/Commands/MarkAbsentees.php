<?php

namespace App\Console\Commands;

use App\Models\Employee;
use App\Models\LeaveRequest;
use App\Models\WorkSchedule;
use App\Services\ScheduleService;
use Carbon\Carbon;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('app:mark-absentees {--date=}')]
#[Description('Tandai alfa karyawan yang tidak absen dan tidak punya izin di hari kerja lewat.')]
class MarkAbsentees extends Command
{
    public function handle(ScheduleService $schedule): int
    {
        $tz = WorkSchedule::current()?->timezone ?? config('app.timezone');
        $date = $this->option('date')
            ? Carbon::parse($this->option('date'), $tz)->startOfDay()
            : Carbon::yesterday($tz);

        if (! $schedule->isWorkday($date)) {
            $this->info('Bukan hari kerja, tidak ada yang ditandai.');

            return self::SUCCESS;
        }

        $marked = 0;

        Employee::where('is_active', true)->whereNotNull('user_id')->with('user')->get()
            ->filter(fn (Employee $employee) => $employee->user && $employee->user->is_active)
            ->each(function (Employee $employee) use ($date, &$marked) {
                if ($employee->attendances()->whereDate('date', $date->toDateString())->exists()) {
                    return;
                }

                $onLeave = LeaveRequest::where('employee_id', $employee->id)
                    ->where('status', 'approved')
                    ->whereDate('start_date', '<=', $date)
                    ->whereDate('end_date', '>=', $date)
                    ->exists();

                if ($onLeave) {
                    return;
                }

                $employee->attendances()->create([
                    'date' => $date->toDateString(),
                    'is_absent' => true,
                    'late_minutes' => 0,
                    'early_leave_minutes' => 0,
                ]);

                $marked++;
            });

        $this->info('Ditandai alfa: '.$marked);

        return self::SUCCESS;
    }
}
