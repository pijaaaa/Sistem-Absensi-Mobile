<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\FaceException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\AttendanceRequest;
use App\Models\Attendance;
use App\Models\Device;
use App\Models\Employee;
use App\Models\FaceTemplate;
use App\Services\AttendanceService;
use App\Services\DeviceService;
use App\Services\Face\FaceServiceClient;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    public function __construct(
        private AttendanceService $attendance,
        private DeviceService $devices,
        private FaceServiceClient $face,
        private NotificationService $notifier,
    ) {}

    public function checkIn(AttendanceRequest $request): JsonResponse
    {
        [$employee, $device] = $this->context($request);

        $photo = $request->file('photo');
        $score = $this->verifyFace(
            $employee,
            $photo->get(),
            $photo->getClientOriginalName(),
            (float) $request->input('face_score_local', 1.0),
        );

        $result = $this->attendance->checkIn($employee, $device, $request->validated(), $score);
        $attendance = $result['attendance'];

        $this->storeCapture($attendance, 'in', $photo);

        if ($attendance->is_backup_device) {
            $this->notifier->sendMany(
                $this->notifier->approversFor($employee),
                'Approval kehadiran',
                $employee->name.' absen dari device cadangan, menunggu approval.',
                ['type' => 'backup_attendance_request', 'id' => $attendance->id],
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Absen masuk berhasil.',
            'data' => array_merge($this->attendance->statusPayload($attendance), [
                'id' => $attendance->id,
                'date' => $attendance->date->toDateString(),
                'check_in_at' => $attendance->check_in_at->toIso8601String(),
                'is_dinas' => $attendance->is_dinas,
            ]),
        ]);
    }

    public function checkOut(AttendanceRequest $request): JsonResponse
    {
        [$employee, $device] = $this->context($request);

        $photo = $request->file('photo');
        $score = $this->verifyFace(
            $employee,
            $photo->get(),
            $photo->getClientOriginalName(),
            (float) $request->input('face_score_local', 1.0),
        );

        $attendance = $this->attendance->checkOut($employee, $device, $request->validated(), $score);

        $this->storeCapture($attendance, 'out', $photo);

        return response()->json([
            'success' => true,
            'message' => 'Absen pulang berhasil.',
            'data' => [
                'id' => $attendance->id,
                'check_out_at' => $attendance->check_out_at->toIso8601String(),
                'early_leave_minutes' => $attendance->early_leave_minutes,
            ],
        ]);
    }

    /**
     * @return array{0: Employee, 1: Device}
     */
    private function context(Request $request): array
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            throw new FaceException('no_employee', 'Profil karyawan tidak ditemukan.', 422);
        }

        $deviceUid = $request->validated('device_uid');

        try {
            $device = $this->devices->resolveForAttendance($employee, $deviceUid);
        } catch (\Throwable) {
            throw new FaceException('device_error', 'Device tidak terdaftar. Daftarkan device utama/cadangan dulu.', 422);
        }

        return [$employee, $device];
    }

    private function verifyFace(Employee $employee, string $bytes, string $name, ?float $fallbackScore = 1.0): float
    {
        $templates = $employee->faceTemplates()->get();

        if ($templates->isEmpty()) {
            throw new FaceException('no_template', 'Wajah belum terdaftar.', 422);
        }

        $best = null;

        try {
            foreach ($templates as $template) {
                $result = $this->face->verify($bytes, $template->embedding, $name);

                if ($best === null || $result['score'] > $best['score']) {
                    $best = $result;
                }
            }
        } catch (\Throwable $e) {
            \Log::warning('Face verify service unavailable; falling back to local score. '.$e->getMessage());
            return $fallbackScore;
        }

        if ($best === null || ! $best['match']) {
            throw new FaceException('face_mismatch', 'Wajah tidak cocok.', 422);
        }

        return $best['score'];
    }

    /**
     * First-time grace: jika karyawan belum punya template, enroll otomatis
     * dari photo yang dikirim agar akun langsung bisa dipakai di apk.
     * Score otomatis 1.0 (approved) untuk absen pertama.
     *
     * Fallback: bila face-service eksternal (port 8001) mati, pakai embedding
     * dummy agar absen tetap berhasil (dev/local). Log peringatan.
     */
    private function autoEnrollFace(Employee $employee, string $bytes, string $name): float
    {
        $modelVersion = config('services.face.model_version', 'sface-2021dec+yunet-2023mar');

        try {
            $result = $this->face->embed($bytes, $name);
            $embedding = array_map('floatval', $result['embedding']);
        } catch (\Throwable $e) {
            \Log::warning('Face embed failed on auto-enroll (guest fallback): '.$e->getMessage());
            $embedding = $this->dummyEmbedding(128);
        }

        DB::transaction(function () use ($employee, $embedding, $modelVersion) {
            FaceTemplate::create([
                'employee_id' => $employee->id,
                'embedding' => $embedding,
                'model_version' => $modelVersion,
            ]);
        });

        return 1.0;
    }

    private function dummyEmbedding(int $dimension): array
    {
        return array_fill(0, $dimension, 0.0);
    }

    private function storeCapture(Attendance $attendance, string $type, $photo): void
    {
        $path = $photo->store('face_captures', 'local');

        $attendance->faceCaptures()->create([
            'type' => $type,
            'path' => $path,
            'expires_at' => now()->addDays(30),
        ]);
    }
}
