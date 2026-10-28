<?php

namespace App\Console\Commands;

use App\Models\Employee;
use App\Models\LeaveBalance;
use App\Models\Setting;
use App\Models\WorkSchedule;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('notifications:leave-expiry')]
#[Description('Kirim notifikasi sisa cuti akan hangus (Fase 2 #10).')]
class NotifyLeaveExpiryCommand extends Command
{
    public function handle(NotificationService $notifier): int
    {
        $tz = WorkSchedule::current()?->timezone ?? config('app.timezone');
        $today = Carbon::now($tz)->format('m-d');
        $year = (int) Carbon::now($tz)->year;

        $dates = array_map('trim', explode(',', (string) Setting::get('notif_leave_expiry_dates', '11-01,12-15')));

        if (! in_array($today, $dates, true)) {
            $this->info('Bukan tanggal pengingat cuti ('.$today.'). Dilewati.');

            return self::SUCCESS;
        }

        $threshold = (int) Setting::get('notif_leave_expiry_threshold', 3);
        $count = 0;

        Employee::where('is_active', true)
            ->whereNotNull('user_id')
            ->whereHas('user', fn ($q) => $q->where('is_active', true))
            ->with('user')
            ->get()
            ->each(function (Employee $employee) use ($year, $threshold, $notifier, $today, &$count) {
                $balance = LeaveBalance::where('employee_id', $employee->id)
                    ->where('year', $year)
                    ->first();

                if (! $balance) {
                    return;
                }

                $remaining = max(0, $balance->quota - $balance->used);

                if ($remaining < $threshold) {
                    return;
                }

                $notifier->send(
                    $employee->user,
                    'Sisa cuti akan hangus',
                    "Sisa cuti Anda {$remaining} hari dan akan hangus pada 31 Desember.",
                    ['type' => 'leave_balance_expiring'],
                    'leave_balance_expiring:'.$employee->id.':'.$year.':'.$today,
                );

                $count++;
            });

        $this->info("Notifikasi sisa cuti dikirim: {$count}.");

        return self::SUCCESS;
    }
}
