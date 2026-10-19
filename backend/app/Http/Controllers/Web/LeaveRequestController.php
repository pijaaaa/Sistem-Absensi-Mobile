<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use App\Services\LeaveRequestService;
use App\Services\NotificationService;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class LeaveRequestController extends Controller
{
    public function __construct(
        private LeaveRequestService $service,
        private NotificationService $notifier,
    ) {}

    public function index(Request $request): View
    {
        $status = $request->input('status', 'pending');

        $requests = LeaveRequest::with('employee.user', 'employee.department')
            ->when($status !== 'all', fn ($q) => $q->where('status', $status))
            ->whereHas('employee.user', fn ($u) => $u->where('role', 'manager_department'))
            ->latest()
            ->get();

        return view('leave-requests.index', compact('requests', 'status'));
    }

    public function approve(LeaveRequest $leaveRequest): RedirectResponse
    {
        $this->ensureManagerRequest($leaveRequest);
        $this->ensurePending($leaveRequest);

        $this->service->approve($leaveRequest, auth()->id());
        AuditLogger::record('leave.approved', $leaveRequest, null, ['status' => 'approved']);
        $this->notifyRequester($leaveRequest);

        return back()->with('status', 'Pengajuan manager disetujui.');
    }

    public function reject(Request $request, LeaveRequest $leaveRequest): RedirectResponse
    {
        $data = $request->validate(['rejection_reason' => ['required', 'string', 'max:1000']], [
            'rejection_reason.required' => 'Alasan penolakan wajib diisi.',
        ]);

        $this->ensureManagerRequest($leaveRequest);
        $this->ensurePending($leaveRequest);

        $this->service->reject($leaveRequest, auth()->id(), $data['rejection_reason']);
        AuditLogger::record('leave.rejected', $leaveRequest, null, ['status' => 'rejected']);
        $this->notifyRequester($leaveRequest);

        return back()->with('status', 'Pengajuan manager ditolak.');
    }

    private function notifyRequester(LeaveRequest $leave): void
    {
        if ($user = $leave->employee?->user) {
            $this->notifier->send(
                $user,
                'Pengajuan '.$leave->status,
                sprintf('Pengajuan %s Anda %s.', $leave->type, $leave->status === 'approved' ? 'disetujui' : 'ditolak'),
                ['type' => 'leave_decision', 'id' => $leave->id],
            );
        }
    }

    private function ensureManagerRequest(LeaveRequest $leave): void
    {
        if ($leave->employee?->user?->role->value !== 'manager_department') {
            abort(403, 'Halaman ini untuk pengajuan manager.');
        }
    }

    private function ensurePending(LeaveRequest $leave): void
    {
        if ($leave->status !== 'pending') {
            throw ValidationException::withMessages(['status' => 'Pengajuan sudah diputuskan.']);
        }
    }
}
