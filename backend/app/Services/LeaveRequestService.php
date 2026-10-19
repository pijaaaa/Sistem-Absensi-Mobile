<?php

namespace App\Services;

use App\Models\Employee;
use App\Models\LeaveBalance;
use App\Models\LeaveRequest;
use App\Models\Setting;
use App\Models\WorkSchedule;
use Carbon\Carbon;
use Illuminate\Validation\ValidationException;

class LeaveRequestService
{
    public function __construct(private ScheduleService $schedule) {}

    public function create(Employee $employee, array $data): LeaveRequest
    {
        $start = Carbon::parse($data['start_date'])->startOfDay();
        $end = Carbon::parse($data['end_date'])->startOfDay();

        if ($end->lessThan($start)) {
            throw ValidationException::withMessages(['end_date' => 'Tanggal selesai harus setelah tanggal mulai.']);
        }

        $this->ensureNotOverlapping($employee, $start, $end);
        $this->ensureWithinBackdateLimit($data['type'], $start);

        if ($data['type'] === 'cuti') {
            $days = $this->workingDays($start, $end);

            if ($this->availableBalance($employee) < $days) {
                throw ValidationException::withMessages(['start_date' => 'Saldo cuti tidak mencukupi.']);
            }
        }

        return $employee->leaveRequests()->create([
            'type' => $data['type'],
            'start_date' => $start->toDateString(),
            'end_date' => $end->toDateString(),
            'reason' => $data['reason'] ?? null,
            'attachment_path' => $data['attachment_path'] ?? null,
            'status' => 'pending',
        ]);
    }

    public function approve(LeaveRequest $request, int $approverId): void
    {
        if ($request->type === 'cuti') {
            $days = $this->workingDays($request->start_date, $request->end_date);
            $balance = $this->balanceFor($request->employee, (int) $request->start_date->year);
            $balance->increment('used', $days);
        }

        $request->update(['status' => 'approved', 'approver_id' => $approverId]);
    }

    public function reject(LeaveRequest $request, int $approverId, ?string $reason): void
    {
        $request->update([
            'status' => 'rejected',
            'approver_id' => $approverId,
            'rejection_reason' => $reason,
        ]);
    }

    public function workingDays(Carbon $start, Carbon $end): int
    {
        $count = 0;
        $cursor = $start->copy();

        while ($cursor->lessThanOrEqualTo($end)) {
            if ($this->schedule->isWorkday($cursor)) {
                $count++;
            }
            $cursor->addDay();
        }

        return $count;
    }

    public function availableBalance(Employee $employee): int
    {
        $year = (int) Carbon::now($this->timezone())->year;
        $balance = $this->balanceFor($employee, $year);

        return max(0, $balance->quota - $balance->used);
    }

    public function balanceFor(Employee $employee, int $year): LeaveBalance
    {
        return LeaveBalance::firstOrCreate(
            ['employee_id' => $employee->id, 'year' => $year],
            ['quota' => (int) Setting::get('leave_quota_default', 12), 'used' => 0]
        );
    }

    private function ensureNotOverlapping(Employee $employee, Carbon $start, Carbon $end): void
    {
        $overlap = $employee->leaveRequests()
            ->where('status', '!=', 'rejected')
            ->whereDate('start_date', '<=', $end)
            ->whereDate('end_date', '>=', $start)
            ->exists();

        if ($overlap) {
            throw ValidationException::withMessages(['start_date' => 'Rentang tanggal tumpang tindih dengan pengajuan lain.']);
        }
    }

    private function ensureWithinBackdateLimit(string $type, Carbon $start): void
    {
        $today = Carbon::now($this->timezone())->startOfDay();

        if (in_array($type, ['izin', 'sakit'], true)) {
            $limit = $today->copy()->subDays((int) Setting::get('max_backdated_days', 3));

            if ($start->lessThan($limit)) {
                throw ValidationException::withMessages(['start_date' => 'Pengajuan mundur melebihi batas yang diizinkan.']);
            }

            return;
        }

        if ($start->lessThan($today)) {
            throw ValidationException::withMessages(['start_date' => 'Tanggal mulai tidak boleh di masa lalu.']);
        }
    }

    private function timezone(): string
    {
        return WorkSchedule::current()?->timezone ?? config('app.timezone');
    }
}
