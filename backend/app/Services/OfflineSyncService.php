<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\Device;
use App\Models\Employee;
use App\Models\LatenessRule;
use App\Models\LeaveRequest;
use App\Models\WorkSchedule;
use Carbon\Carbon;
use Illuminate\Support\Facades\Storage;

class OfflineSyncService
{
    public function __construct(
        private GeofenceService $geofence,
        private ScheduleService $schedule,
        private LatenessService $lateness,
        private DinasService $dinas,
        private Face\FaceServiceClient $face,
    ) {}

    public function serverTime(): array
    {
        $schedule = WorkSchedule::current();
        $tz = $schedule?->timezone ?? config('app.timezone');

        return [
            'server_time' => Carbon::now($tz)->toIso8601String(),
            'timezone' => $tz,
        ];
    }

    /**
     * Proses batch absen offline. Setiap item independen & idempotent via client_uuid.
     *
     * @return array<int, array<string, mixed>>
     */
    public function sync(Employee $employee, array $payload): array
    {
        $schedule = WorkSchedule::current();
        $tz = $schedule?->timezone ?? config('app.timezone');
        $anchor = $payload['anchor'];
        $anchorServer = Carbon::parse($anchor['server_time']);
        $bootChanged = (int) $payload['boot_count'] !== (int) $anchor['boot_count'];

        $results = [];

        foreach ($payload['items'] as $item) {
            $results[] = $this->syncItem($employee, $item, $anchor, $anchorServer, $bootChanged, $schedule, $tz);
        }

        return $results;
    }

    private function syncItem(
        Employee $employee,
        array $item,
        array $anchor,
        Carbon $anchorServer,
        bool $bootChanged,
        ?WorkSchedule $schedule,
        string $tz,
    ): array {
        $uuid = $item['client_uuid'];

        if (Attendance::where('client_uuid', $uuid)->exists()) {
            return ['client_uuid' => $uuid, 'status' => 'duplicate'];
        }

        $recomputed = $anchorServer->copy()->addMilliseconds(
            (int) $item['elapsed_realtime'] - (int) $anchor['elapsed_realtime']
        )->setTimezone($tz);

        $date = $recomputed->toDateString();

        if (Attendance::where('employee_id', $employee->id)->whereDate('date', $date)->exists()) {
            return ['client_uuid' => $uuid, 'status' => 'skipped_existing'];
        }

        $device = Device::where('employee_id', $employee->id)
            ->where('device_uid', $item['device_uid'])
            ->where('status', 'active')
            ->first();

        $isBackup = $device && $device->type === 'backup';

        $isDinas = $this->isDinas($employee, $recomputed);

        $insideArea = $isDinas || $this->insideArea($employee, (float) $item['lat'], (float) $item['lng']);

        $reviewFlag = $bootChanged || ! $insideArea || $device === null;

        $late = null;

        if ($item['type'] === 'in' && $schedule) {
            $start = Carbon::parse($date.' '.$schedule->start_time, $tz);
            $late = $this->lateness->evaluate($recomputed, $start, LatenessRule::orderBy('from_minute')->get());
        }

        [$scoreServer, $match] = $this->verifyFace($employee, $item['photo'] ?? null);

        if (! $match) {
            $reviewFlag = true;
        }

        $attributes = [
            'date' => $date,
            'is_offline' => true,
            'time_trust' => $bootChanged ? 'suspect' : 'ok',
            'client_uuid' => $uuid,
            'device_id' => $device?->id,
            'is_backup_device' => (bool) $isBackup,
            'approval_status' => $isBackup ? 'pending' : 'none',
            'is_dinas' => $isDinas,
            'face_score_local' => $item['face_score_local'] ?? null,
            'face_score_server' => $scoreServer,
            'review_flag' => $reviewFlag,
        ];

        if ($item['type'] === 'in') {
            $attributes += [
                'check_in_at' => $recomputed,
                'in_lat' => $item['lat'],
                'in_lng' => $item['lng'],
                'location_id' => $employee->work_location_id,
                'late_minutes' => $late?->minutes ?? 0,
                'late_level' => $late?->color ?? 'green',
            ];
        } else {
            $attributes += [
                'check_out_at' => $recomputed,
                'out_lat' => $item['lat'],
                'out_lng' => $item['lng'],
            ];
        }

        $attendance = $employee->attendances()->create($attributes);

        if (! empty($item['photo'])) {
            $this->storeCapture($attendance, $item['type'], $item['photo']);
        }

        return [
            'client_uuid' => $uuid,
            'status' => 'created',
            'attendance_id' => $attendance->id,
            'review_flag' => $reviewFlag,
            'time_trust' => $attendance->time_trust,
        ];
    }

    private function isDinas(Employee $employee, Carbon $moment): bool
    {
        $ranges = LeaveRequest::query()
            ->where('employee_id', $employee->id)
            ->where('type', 'dinas')
            ->where('status', 'approved')
            ->get(['start_date', 'end_date'])
            ->map(fn ($r) => ['start' => $r->start_date, 'end' => $r->end_date]);

        return $this->dinas->coversDate($moment, $ranges);
    }

    private function insideArea(Employee $employee, float $lat, float $lng): bool
    {
        $location = $employee->workLocation;

        if (! $location || $location->mode === 'off') {
            return true;
        }

        return $this->geofence->check($location, $lat, $lng);
    }

    /**
     * @return array{0: float|null, 1: bool}
     */
    private function verifyFace(Employee $employee, ?string $photo): array
    {
        $templates = $employee->faceTemplates()->get();

        if ($templates->isEmpty() || ! $photo) {
            return [null, false];
        }

        $bytes = $this->decodePhoto($photo);
        $best = null;

        foreach ($templates as $template) {
            $result = $this->face->verify($bytes, $template->embedding, 'offline.jpg');

            if ($best === null || $result['score'] > $best['score']) {
                $best = $result;
            }
        }

        return [$best['score'], $best['match']];
    }

    private function decodePhoto(string $photo): string
    {
        if (str_contains($photo, 'base64,')) {
            $photo = explode('base64,', $photo, 2)[1];
        }

        return base64_decode($photo, true) ?: '';
    }

    private function storeCapture(Attendance $attendance, string $type, string $photo): void
    {
        $bytes = $this->decodePhoto($photo);

        if ($bytes === '') {
            return;
        }

        $path = 'face_captures/'.$attendance->id.'-'.$type.'.jpg';
        Storage::disk('local')->put($path, $bytes);

        $attendance->faceCaptures()->create([
            'type' => $type,
            'path' => $path,
            'expires_at' => now()->addDays(30),
        ]);
    }
}
