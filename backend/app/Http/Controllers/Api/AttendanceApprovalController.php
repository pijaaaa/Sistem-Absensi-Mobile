<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Support\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class AttendanceApprovalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $attendances = Attendance::with('employee')
            ->where('approval_status', 'pending')
            ->when(! $request->user()->isSuperadmin(), function ($query) use ($request) {
                $departmentId = $request->user()->employee?->department_id;
                $query->whereHas('employee', fn ($q) => $q->where('department_id', $departmentId));
            })
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $attendances->map(fn (Attendance $a) => [
                'id' => $a->id,
                'employee' => $a->employee?->name,
                'date' => $a->date->toDateString(),
                'check_in_at' => $a->check_in_at?->toIso8601String(),
                'is_backup_device' => $a->is_backup_device,
                'face_score_server' => $a->face_score_server,
            ]),
        ]);
    }

    public function approve(Request $request, Attendance $attendance): JsonResponse
    {
        return $this->decide($request, $attendance, 'approved');
    }

    public function reject(Request $request, Attendance $attendance): JsonResponse
    {
        return $this->decide($request, $attendance, 'rejected');
    }

    private function decide(Request $request, Attendance $attendance, string $status): JsonResponse
    {
        $this->authorizeDepartment($request, $attendance);

        if ($attendance->approval_status !== 'pending') {
            throw ValidationException::withMessages(['attendance' => 'Absensi ini sudah diputuskan.']);
        }

        $attendance->update([
            'approval_status' => $status,
            'approver_id' => $request->user()->id,
        ]);

        AuditLogger::record('attendance.'.$status, $attendance, null, ['approval_status' => $status]);

        return response()->json([
            'success' => true,
            'message' => $status === 'approved' ? 'Kehadiran disetujui.' : 'Kehadiran ditolak.',
            'data' => ['id' => $attendance->id, 'approval_status' => $status],
        ]);
    }

    private function authorizeDepartment(Request $request, Attendance $attendance): void
    {
        if ($request->user()->isSuperadmin()) {
            return;
        }

        $departmentId = $request->user()->employee?->department_id;

        if (! $departmentId || $attendance->employee?->department_id !== $departmentId) {
            abort(403, 'Hanya manager department yang sama.');
        }
    }
}
