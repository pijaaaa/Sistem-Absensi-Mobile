<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\LeaveBalance;
use App\Models\Setting;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class LeaveBalanceController extends Controller
{
    public function index(Request $request): View
    {
        $year = (int) $request->input('year', now()->year);
        $employees = Employee::with(['department', 'user'])
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $balances = LeaveBalance::where('year', $year)
            ->whereIn('employee_id', $employees->pluck('id'))
            ->get()
            ->keyBy('employee_id');

        $defaultQuota = (int) Setting::get('leave_quota_default', 12);

        return view('leave-balances.index', compact('employees', 'balances', 'year', 'defaultQuota'));
    }

    public function update(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'year' => ['required', 'integer', 'min:2000', 'max:2100'],
            'default_quota' => ['required', 'integer', 'min:0', 'max:365'],
            'quotas' => ['nullable', 'array'],
            'quotas.*' => ['nullable', 'integer', 'min:0', 'max:365'],
        ]);

        $old = Setting::get('leave_quota_default', 12);
        Setting::put('leave_quota_default', $data['default_quota'], 'Jatah cuti default/tahun');

        foreach ($data['quotas'] ?? [] as $employeeId => $quota) {
            if ($quota === null || $quota === '') {
                continue;
            }

            LeaveBalance::updateOrCreate(
                ['employee_id' => $employeeId, 'year' => $data['year']],
                ['quota' => $quota]
            );
        }

        AuditLogger::record('leave_quota.updated', null, ['default' => $old], [
            'default' => $data['default_quota'],
            'year' => $data['year'],
        ]);

        return back()->with('status', 'Jatah cuti disimpan.');
    }
}
