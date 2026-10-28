<?php

namespace App\Console\Commands;

use App\Models\Employee;
use App\Models\LeaveRequest;
use App\Models\Setting;
use App\Models\User;
use App\Models\WorkSchedule;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('notifications:pending-approval')]
#[Description('Kirim ringkasan pengajuan pending >24 jam ke manager (Fase 2 #8).')]
class NotifyPendingApprovalCommand extends Command
{
    public function handle(NotificationService $notifier): int
    {
        if (! Setting::get('notif_pending_approval_enabled', 1)) {
            $this->info('Notifikasi pending approval dinonaktifkan.');

            return self::SUCCESS;
        }

        $tz = WorkSchedule::current()?->timezone ?? config('app.timezone');
        $today = Carbon::now($tz)->toDateString();
        $threshold = Carbon::now($tz)->subHours(24);
        $count = 0;

        $pendingLeaves = LeaveRequest::where('status', 'pending')
            ->where('created_at', '<=', $threshold)
            ->get();

        User::where('role', 'manager_department')
            ->where('is_active', true)
            ->with('employee')
            ->get()
            ->each(function (User $manager) use ($pendingLeaves, $notifier, $today, &$count) {
                $departmentId = $manager->employee?->department_id;

                if (! $departmentId) {
                    return;
                }

                $deptEmployeeIds = Employee::where('department_id', $departmentId)
                    ->whereNotNull('user_id')
                    ->whereHas('user', fn ($q) => $q->where('role', 'karyawan'))
                    ->pluck('id');

                $pendingCount = $pendingLeaves->whereIn('employee_id', $deptEmployeeIds)->count();

                if ($pendingCount === 0) {
                    return;
                }

                $notifier->send(
                    $manager,
                    'Pengajuan menunggu',
                    "{$pendingCount} pengajuan menunggu persetujuan Anda lebih dari 24 jam.",
                    ['type' => 'pending_approval_digest'],
                    'pending_approval_digest:'.$manager->id.':'.$today,
                );

                $count++;
            });

        $this->info("Notifikasi pending approval dikirim: {$count}.");

        return self::SUCCESS;
    }
}
