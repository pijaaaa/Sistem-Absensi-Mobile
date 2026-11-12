<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Services\NotificationService;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AttendanceApprovalController extends Controller
{
    public function __construct(private NotificationService $notifier) {}

    public function index(Request $request): View
    {
        $attendances = Attendance::with('employee.department')
            ->where('approval_status', 'pending')
            ->when(! $request->user()->isSuperadmin(), function ($query) use ($request) {
                $departmentId = $request->user()->employee?->department_id;
                $query->whereHas('employee', fn ($q) => $q->where('department_id', $departmentId));
            })
            ->latest()
            ->paginate(15)
            ->withQueryString();

        return view('attendance-approval.index', compact('attendances'));
    }

    public function approve(Request $request, Attendance $attendance): RedirectResponse
    {
        return $this->decide($request, $attendance, 'approved');
    }

    public function reject(Request $request, Attendance $attendance): RedirectResponse
    {
        return $this->decide($request, $attendance, 'rejected');
    }

    private function decide(Request $request, Attendance $attendance, string $status): RedirectResponse
    {
        if (! $request->user()->isSuperadmin() && $attendance->employee?->department_id !== $request->user()->employee?->department_id) {
            abort(403, 'Hanya manager department yang sama.');
        }

        abort_if($attendance->approval_status !== 'pending', 422, 'Absensi ini sudah diputuskan.');

        $attendance->update([
            'approval_status' => $status,
            'approver_id' => $request->user()->id,
        ]);

        AuditLogger::record('attendance.'.$status, $attendance, null, ['approval_status' => $status]);

        if ($user = $attendance->employee?->user) {
            $this->notifier->send(
                $user,
                'Kehadiran device cadangan '.$status,
                'Absensi device cadangan Anda '.($status === 'approved' ? 'disetujui' : 'ditolak').'.',
                ['type' => 'backup_attendance_decision', 'id' => $attendance->id],
            );
        }

        return back()->with('status', $status === 'approved' ? 'Kehadiran disetujui.' : 'Kehadiran ditolak.');
    }
}
