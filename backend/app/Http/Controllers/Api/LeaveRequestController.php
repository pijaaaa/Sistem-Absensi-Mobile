<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use App\Services\LeaveRequestService;
use App\Support\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class LeaveRequestController extends Controller
{
    public function __construct(private LeaveRequestService $service) {}

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'type' => ['required', 'in:cuti,sakit,izin,dinas'],
            'start_date' => ['required', 'date'],
            'end_date' => ['required', 'date', 'after_or_equal:start_date'],
            'reason' => ['nullable', 'string', 'max:1000'],
            'attachment' => ['nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ], [
            'end_date.after_or_equal' => 'Tanggal selesai harus setelah tanggal mulai.',
        ]);

        $employee = $request->user()->employee;

        if (! $employee) {
            return $this->error('Profil karyawan tidak ditemukan.');
        }

        if ($request->hasFile('attachment')) {
            $data['attachment_path'] = $request->file('attachment')->store('leave_attachments', 'local');
        }

        $leave = $this->service->create($employee, $data);

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan terkirim.',
            'data' => $this->payload($leave),
        ], 201);
    }

    public function index(Request $request): JsonResponse
    {
        $requests = $request->user()->employee?->leaveRequests()->latest()->get() ?? collect();

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $requests->map(fn (LeaveRequest $r) => $this->payload($r)),
        ]);
    }

    public function balance(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return $this->error('Profil karyawan tidak ditemukan.');
        }

        $balance = $this->service->balanceFor($employee, (int) now()->year);

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => [
                'year' => $balance->year,
                'quota' => $balance->quota,
                'used' => $balance->used,
                'remaining' => max(0, $balance->quota - $balance->used),
            ],
        ]);
    }

    public function inbox(Request $request): JsonResponse
    {
        $user = $request->user();
        $departmentId = $user->employee?->department_id;

        $requests = LeaveRequest::with('employee')
            ->where('status', 'pending')
            ->when(! $user->isSuperadmin(), fn ($q) => $q
                ->whereHas('employee', fn ($e) => $e
                    ->where('department_id', $departmentId)
                    ->whereHas('user', fn ($u) => $u->where('role', 'karyawan'))))
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $requests->map(fn (LeaveRequest $r) => $this->payload($r) + ['employee' => $r->employee?->name]),
        ]);
    }

    public function approve(Request $request, LeaveRequest $leave): JsonResponse
    {
        $this->authorizeApproval($request, $leave);
        $this->ensurePending($leave);

        $this->service->approve($leave, $request->user()->id);
        AuditLogger::record('leave.approved', $leave, null, ['status' => 'approved']);

        return response()->json(['success' => true, 'message' => 'Pengajuan disetujui.', 'data' => $this->payload($leave->fresh())]);
    }

    public function reject(Request $request, LeaveRequest $leave): JsonResponse
    {
        $data = $request->validate(['reason' => ['required', 'string', 'max:1000']], [
            'reason.required' => 'Alasan penolakan wajib diisi.',
        ]);

        $this->authorizeApproval($request, $leave);
        $this->ensurePending($leave);

        $this->service->reject($leave, $request->user()->id, $data['reason']);
        AuditLogger::record('leave.rejected', $leave, null, ['status' => 'rejected']);

        return response()->json(['success' => true, 'message' => 'Pengajuan ditolak.', 'data' => $this->payload($leave->fresh())]);
    }

    private function authorizeApproval(Request $request, LeaveRequest $leave): void
    {
        if ($request->user()->isSuperadmin()) {
            return;
        }

        $departmentId = $request->user()->employee?->department_id;
        $requester = $leave->employee;

        $sameDepartment = $departmentId && $requester?->department_id === $departmentId && $requester?->user?->role->value === 'karyawan';

        if (! $sameDepartment) {
            abort(403, 'Hanya manager department yang sama yang boleh memutuskan pengajuan karyawan.');
        }
    }

    private function ensurePending(LeaveRequest $leave): void
    {
        if ($leave->status !== 'pending') {
            throw ValidationException::withMessages(['status' => 'Pengajuan sudah diputuskan.']);
        }
    }

    private function payload(LeaveRequest $leave): array
    {
        return [
            'id' => $leave->id,
            'type' => $leave->type,
            'start_date' => $leave->start_date->toDateString(),
            'end_date' => $leave->end_date->toDateString(),
            'reason' => $leave->reason,
            'status' => $leave->status,
            'rejection_reason' => $leave->rejection_reason,
        ];
    }

    private function error(string $message): JsonResponse
    {
        return response()->json(['success' => false, 'message' => $message, 'errors' => (object) []], 422);
    }
}
