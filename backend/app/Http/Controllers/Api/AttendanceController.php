<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\FaceException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\AttendanceRequest;
use App\Models\Attendance;
use App\Models\Device;
use App\Models\Employee;
use App\Services\AttendanceService;
use App\Services\DeviceService;
use App\Services\Face\FaceServiceClient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function __construct(
        private AttendanceService $attendance,
        private DeviceService $devices,
        private FaceServiceClient $face,
    ) {}

    public function checkIn(AttendanceRequest $request): JsonResponse
    {
        [$employee, $device] = $this->context($request);

        $photo = $request->file('photo');
        $score = $this->verifyFace($employee->faceTemplates()->get(), $photo->get(), $photo->getClientOriginalName());

        $result = $this->attendance->checkIn($employee, $device, $request->validated(), $score);
        $attendance = $result['attendance'];

        $this->storeCapture($attendance, 'in', $photo);

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
        $score = $this->verifyFace($employee->faceTemplates()->get(), $photo->get(), $photo->getClientOriginalName());

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

        $device = $this->devices->resolveForAttendance($employee, $request->validated('device_uid'));

        return [$employee, $device];
    }

    private function verifyFace($templates, string $bytes, string $name): float
    {
        if ($templates->isEmpty()) {
            throw new FaceException('no_template', 'Wajah belum terdaftar.', 422);
        }

        $best = null;

        foreach ($templates as $template) {
            $result = $this->face->verify($bytes, $template->embedding, $name);

            if ($best === null || $result['score'] > $best['score']) {
                $best = $result;
            }
        }

        if (! $best['match']) {
            throw new FaceException('face_mismatch', 'Wajah tidak cocok.', 422);
        }

        return $best['score'];
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
