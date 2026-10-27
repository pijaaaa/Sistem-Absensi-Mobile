<?php

namespace App\Services;

use App\Jobs\SendPushNotification;
use App\Models\Employee;
use App\Models\LeaveRequest;
use App\Models\Setting;
use App\Models\User;
use App\Models\WorkSchedule;
use Carbon\Carbon;
use Carbon\CarbonInterface;

/**
 * Reminder harian (Fase 1).
 *
 * Dipanggil via command `notifications:send-reminders` tiap 5 menit.
 * - Hanya kirim ke karyawan yang *wajib* absen (hari kerja, tidak sedang
 *   cuti/sakit/izin/dinas yang disetujui, punya token).
 * - Waktu hitung dari WorkSchedule (timezone) + offset di settings.
 * - Anti-duplikat lewat dedupe_key (jenis:employee_id:tanggal).
 */
class AttendanceReminderService
{
    public function __construct(
        private NotificationService $notifier,
        private ScheduleService $schedule,
    ) {}

    private function tz(): string
    {
        return WorkSchedule::current()?->timezone ?? config('app.timezone');
    }

    /** Karyawan aktif, punya user aktif + setidaknya satu push token, hari kerja, & tidak cuti yang menutupi date. */
    public function isRequiredToAttend(Employee $employee, CarbonInterface $date): bool
    {
        $user = $employee->user;
        if (! $user || ! $user->is_active) {
            return false;
        }

        if ($employee->pushTokens()->count() === 0) {
            return false;
        }

        if (! $this->schedule->isWorkday($date)) {
            return false;
        }

        return ! LeaveRequest::where('employee_id', $employee->id)
            ->where('status', 'approved')
            ->whereDate('start_date', '<=', $date)
            ->whereDate('end_date', '>=', $date)
            ->exists();
    }

    /** @return \Illuminate\Database\Eloquent\Builder<Employee> */
    private function employeesRequired()
    {
        return Employee::where('is_active', true)
            ->whereNotNull('user_id')
            ->whereHas('user', fn ($q) => $q->where('is_active', true))
            ->with('user.pushTokens');
    }

    /** Berada dalam [target, target+buffer] menit. */
    private function inWindow(CarbonInterface $target, CarbonInterface $now, int $buffer = 5): bool
    {
        return ! $now->lessThan($target) && ! $now->greaterThan($target->copy()->addMinutes($buffer));
    }

    public function sendDue(): int
    {
        $schedule = WorkSchedule::current();
        if (! $schedule) {
            return 0;
        }

        $tz = $this->tz();
        $now = Carbon::now($tz);
        $today = $now->toDateString();
        $start = Carbon::parse($today.' '.$schedule->start_time, $tz);
        $end = Carbon::parse($today.' '.$schedule->end_time, $tz);

        $count = 0;
        if (Setting::get('notif_reminder_enabled', 1)) {
            $count += $this->sendCheckinIfDue($today, $now, $start);
            $count += $this->sendCheckoutIfDue($today, $now, $end);
            $count += $this->sendForgotCheckoutIfDue($today, $now, $end);
        }
        $count += $this->sendManagerSummaryIfDue($today, $now);

        return $count;
    }

    private function sendCheckinIfDue(string $today, Carbon $now, Carbon $start): int
    {
        if (! Setting::get('notif_reminder_checkin_enabled', 1)) {
            return 0;
        }

        $target = $start->copy()->subMinutes((int) Setting::get('notif_reminder_checkin_offset', 15));
        if (! $this->inWindow($target, $now)) {
            return 0;
        }

        $date = Carbon::parse($today)->startOfDay($this->tz());
        $count = 0;

        foreach ($this->employeesRequired()->get() as $employee) {
            if (! $this->isRequiredToAttend($employee, $date)) {
                continue;
            }

            // Sudah absen masuk → skip.
            if ($employee->attendances()->whereDate('date', $today)->exists()) {
                continue;
            }

            $this->notifier->send(
                $employee->user,
                'Absensi',
                "Belum absen masuk. Jangan lupa absen sebelum ".$start->format('H:i').'.',
                ['type' => 'reminder_checkin'],
                'reminder_checkin:'.$employee->id.':'.$today,
            );
            $count++;
        }

        return $count;
    }

    private function sendCheckoutIfDue(string $today, Carbon $now, Carbon $end): int
    {
        if (! Setting::get('notif_reminder_checkout_enabled', 1)) {
            return 0;
        }

        $target = $end->copy()->subMinutes((int) Setting::get('notif_reminder_checkout_offset', 15));
        if (! $this->inWindow($target, $now)) {
            return 0;
        }

        $count = 0;

        foreach ($this->employeesRequired()->get() as $employee) {
            $attendance = $employee->attendances()->whereDate('date', $today)->first();
            if (! $attendance || ! $attendance->check_in_at || $attendance->check_out_at) {
                continue;
            }

            $this->notifier->send(
                $employee->user,
                'Absensi',
                'Belum absen pulang? Jangan lupa check-out.',
                ['type' => 'reminder_checkout'],
                'reminder_checkout:'.$employee->id.':'.$today,
            );
            $count++;
        }

        return $count;
    }

    private function sendForgotCheckoutIfDue(string $today, Carbon $now, Carbon $end): int
    {
        if (! Setting::get('notif_reminder_forgot_checkout_enabled', 1)) {
            return 0;
        }

        $target = $end->copy()->addMinutes((int) Setting::get('notif_reminder_forgot_checkout_after', 30));
        // Kirim bila sudah melewati target (worker bisa down) — anti-dobel via dedupe.
        if ($now->lessThan($target)) {
            return 0;
        }

        $count = 0;

        foreach ($this->employeesRequired()->get() as $employee) {
            $attendance = $employee->attendances()->whereDate('date', $today)->first();
            if (! $attendance || ! $attendance->check_in_at || $attendance->check_out_at) {
                continue;
            }

            $this->notifier->send(
                $employee->user,
                'Absensi',
                'Anda belum absen pulang. Silakan lakukan check-out.',
                ['type' => 'reminder_forgot_checkout'],
                'reminder_forgot_checkout:'.$employee->id.':'.$today,
            );
            $count++;
        }

        return $count;
    }

    private function sendManagerSummaryIfDue(string $today, Carbon $now): int
    {
        if (! Setting::get('notif_summary_enabled', 1)) {
            return 0;
        }

        $target = Carbon::parse($today, $this->tz())
            ->setTime((int) Setting::get('notif_summary_hour', 9), (int) Setting::get('notif_summary_minute', 0));

        if (! $this->inWindow($target, $now)) {
            return 0;
        }

        $date = Carbon::parse($today)->startOfDay($this->tz());
        $count = 0;

        foreach (User::where('role', 'manager_department')->with('employee')->get() as $manager) {
            $departmentId = $manager->employee?->department_id;
            if (! $departmentId) {
                continue;
            }

            $required = Employee::where('is_active', true)
                ->where('department_id', $departmentId)
                ->whereNotNull('user_id')
                ->whereHas('user', fn ($q) => $q->where('is_active', true))
                ->get();

            $late = 0;
            $notYet = 0;

            foreach ($required as $employee) {
                $attendance = $employee->attendances()->whereDate('date', $today)->first();

                if (! $attendance || ! $attendance->check_in_at) {
                    $notYet++;
                    continue;
                }

                if (($attendance->late_minutes ?? 0) > 0 && $this->isRequiredToAttend($employee, $date)) {
                    $late++;
                }
            }

            if ($late + $notYet === 0) {
                continue;
            }

            $this->notifier->send(
                $manager,
                'Ringkasan harian tim',
                "Hari ini: {$late} terlambat, {$notYet} belum absen di department Anda.",
                ['type' => 'team_daily_summary'],
                'team_daily_summary:'.$manager->id.':'.$today,
            );
            $count++;
        }

        return $count;
    }
}
