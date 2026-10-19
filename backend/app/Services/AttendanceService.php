<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\Device;
use App\Models\Employee;
use App\Models\LatenessRule;
use App\Models\LeaveRequest;
use App\Models\WorkSchedule;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Validation\ValidationException;

class AttendanceService
{
    public function __construct(
        private GeofenceService $geofence,
        private ScheduleService $schedule,
        private LatenessService $lateness,
        private EarlyLeaveService $earlyLeave,
        private DinasService $dinas,
    ) {}

    /**
     * @return array{attendance: Attendance, dinas: bool}
     */
    public function checkIn(Employee $employee, Device $device, array $data, ?float $faceScoreServer): array
    {
        $schedule = WorkSchedule::current();
        $now = Carbon::now($schedule?->timezone ?? config('app.timezone'));
        $date = $now->toDateString();

        if (! $schedule || ! $this->schedule->isWorkday($now)) {
            throw ValidationException::withMessages(['attendance' => 'Hari ini bukan hari kerja.']);
        }

        if ($employee->attendances()->whereDate('date', $date)->exists()) {
            throw ValidationException::withMessages(['attendance' => 'Sudah absen hari ini.']);
        }

        $isDinas = $this->isOnDinas($employee, $now);
        $this->ensureInsideArea($employee, $isDinas, (float) $data['lat'], (float) $data['lng']);

        $start = Carbon::parse($date.' '.$schedule->start_time, $schedule->timezone);
        $late = $this->lateness->evaluate($now, $start, LatenessRule::orderBy('from_minute')->get());

        $attendance = $employee->attendances()->create([
            'date' => $date,
            'check_in_at' => $now,
            'in_lat' => $data['lat'],
            'in_lng' => $data['lng'],
            'location_id' => $employee->work_location_id,
            'late_minutes' => $late->minutes,
            'late_level' => $late->color ?? 'green',
            'is_dinas' => $isDinas,
            'client_uuid' => $data['client_uuid'] ?? null,
            'device_id' => $device->id,
            'is_backup_device' => $device->type === 'backup',
            'approval_status' => $device->type === 'backup' ? 'pending' : 'none',
            'face_score_local' => $data['face_score_local'] ?? null,
            'face_score_server' => $faceScoreServer,
        ]);

        return ['attendance' => $attendance, 'dinas' => $isDinas];
    }

    public function checkOut(Employee $employee, Device $device, array $data, ?float $faceScoreServer): Attendance
    {
        $schedule = WorkSchedule::current();
        $now = Carbon::now($schedule?->timezone ?? config('app.timezone'));

        $attendance = $employee->attendances()->whereDate('date', $now->toDateString())->first();

        if (! $attendance || ! $attendance->check_in_at) {
            throw ValidationException::withMessages(['attendance' => 'Belum absen masuk hari ini.']);
        }

        if ($attendance->check_out_at) {
            throw ValidationException::withMessages(['attendance' => 'Sudah absen pulang hari ini.']);
        }

        $isDinas = $attendance->is_dinas;
        $this->ensureInsideArea($employee, $isDinas, (float) $data['lat'], (float) $data['lng']);

        $end = Carbon::parse($now->toDateString().' '.$schedule->end_time, $schedule->timezone);

        $attendance->update([
            'check_out_at' => $now,
            'out_lat' => $data['lat'],
            'out_lng' => $data['lng'],
            'early_leave_minutes' => $this->earlyLeave->minutes($now, $end),
            'face_score_server' => $faceScoreServer,
        ]);

        return $attendance;
    }

    public function isOnDinas(Employee $employee, Carbon $date): bool
    {
        $ranges = $this->approvedDinasRanges($employee);

        return $this->dinas->coversDate($date, $ranges);
    }

    /** @return Collection<int, array{start: Carbon, end: Carbon}> */
    private function approvedDinasRanges(Employee $employee): Collection
    {
        return LeaveRequest::query()
            ->where('employee_id', $employee->id)
            ->where('type', 'dinas')
            ->where('status', 'approved')
            ->get(['start_date', 'end_date'])
            ->map(fn ($r) => ['start' => $r->start_date, 'end' => $r->end_date]);
    }

    private function ensureInsideArea(Employee $employee, bool $isDinas, float $lat, float $lng): void
    {
        if ($isDinas) {
            return;
        }

        $location = $employee->workLocation;

        // Mode off atau tanpa lokasi = selalu lolos.
        if (! $location || $location->mode === 'off') {
            return;
        }

        if (! $this->geofence->check($location, $lat, $lng)) {
            throw ValidationException::withMessages(['location' => 'Anda berada di luar area absen.']);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function statusPayload(Attendance $attendance): array
    {
        $counted = $attendance->late_minutes > 0
            && ! in_array($attendance->late_level, [null, 'green'], true);

        return [
            'late_minutes' => $attendance->late_minutes,
            'late_level' => $attendance->late_level,
            'status' => $counted ? 'telat' : 'tepat_waktu',
            'color' => $attendance->late_level ?: 'green',
            'approval_status' => $attendance->approval_status,
        ];
    }
}
