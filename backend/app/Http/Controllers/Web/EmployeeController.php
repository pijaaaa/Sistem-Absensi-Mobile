<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\Web\EmployeeRequest;
use App\Models\Department;
use App\Models\Employee;
use App\Models\User;
use App\Models\WorkLocation;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class EmployeeController extends Controller
{
    public function index(): View
    {
        $employees = Employee::with(['department', 'workLocation', 'user'])
            ->orderBy('name')
            ->paginate(20);

        return view('employees.index', compact('employees'));
    }

    public function create(): View
    {
        return view('employees.form', $this->formData(['employee' => new Employee]));
    }

    public function store(EmployeeRequest $request): RedirectResponse
    {
        $employee = DB::transaction(function () use ($request) {
            $user = User::create([
                'name' => $request->validated('name'),
                'email' => $request->validated('email'),
                'password' => $request->validated('password'),
                'role' => $request->validated('role'),
                'is_active' => $request->boolean('is_active', true),
            ]);

            return Employee::create([
                'user_id' => $user->id,
                'nip' => $request->validated('nip'),
                'name' => $request->validated('name'),
                'department_id' => $request->validated('department_id'),
                'work_location_id' => $request->validated('work_location_id'),
                'is_active' => $request->boolean('is_active', true),
            ]);
        });

        AuditLogger::record('created', $employee, null, $employee->getAttributes());

        return redirect()->route('employees.index')->with('status', 'Karyawan dibuat.');
    }

    public function edit(Employee $employee): View
    {
        return view('employees.form', $this->formData(compact('employee')));
    }

    public function update(EmployeeRequest $request, Employee $employee): RedirectResponse
    {
        $old = $employee->getAttributes();

        DB::transaction(function () use ($request, $employee) {
            $userData = [
                'name' => $request->validated('name'),
                'email' => $request->validated('email'),
                'role' => $request->validated('role'),
                'is_active' => $request->boolean('is_active', true),
            ];

            if ($request->filled('password')) {
                $userData['password'] = $request->validated('password');
            }

            $employee->user->update($userData);

            $employee->update([
                'nip' => $request->validated('nip'),
                'name' => $request->validated('name'),
                'department_id' => $request->validated('department_id'),
                'work_location_id' => $request->validated('work_location_id'),
                'is_active' => $request->boolean('is_active', true),
            ]);
        });

        AuditLogger::record('updated', $employee, $old, $employee->getChanges());

        return redirect()->route('employees.index')->with('status', 'Karyawan diperbarui.');
    }

    public function destroy(Employee $employee): RedirectResponse
    {
        $old = $employee->getAttributes();
        DB::transaction(function () use ($employee) {
            $user = $employee->user;
            $employee->delete();
            $user?->delete();
        });
        AuditLogger::record('deleted', $employee, $old, null);

        return redirect()->route('employees.index')->with('status', 'Karyawan dihapus.');
    }

    /**
     * @return array<string, mixed>
     */
    private function formData(array $extra = []): array
    {
        return array_merge([
            'departments' => Department::orderBy('name')->get(),
            'locations' => WorkLocation::orderBy('name')->get(),
        ], $extra);
    }
}
