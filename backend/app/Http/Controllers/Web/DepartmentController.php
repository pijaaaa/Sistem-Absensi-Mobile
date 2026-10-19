<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\Web\DepartmentRequest;
use App\Models\Department;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class DepartmentController extends Controller
{
    public function index(): View
    {
        $departments = Department::withCount('employees')->orderBy('name')->get();

        return view('departments.index', compact('departments'));
    }

    public function create(): View
    {
        return view('departments.form', ['department' => new Department]);
    }

    public function store(DepartmentRequest $request): RedirectResponse
    {
        $department = Department::create($request->validated());
        AuditLogger::record('created', $department, null, $department->getAttributes());

        return redirect()->route('departments.index')->with('status', 'Department dibuat.');
    }

    public function edit(Department $department): View
    {
        return view('departments.form', compact('department'));
    }

    public function update(DepartmentRequest $request, Department $department): RedirectResponse
    {
        $old = $department->getOriginal();
        $department->update($request->validated());
        AuditLogger::record('updated', $department, $old, $department->getChanges());

        return redirect()->route('departments.index')->with('status', 'Department diperbarui.');
    }

    public function destroy(Department $department): RedirectResponse
    {
        $old = $department->getAttributes();
        $department->delete();
        AuditLogger::record('deleted', $department, $old, null);

        return redirect()->route('departments.index')->with('status', 'Department dihapus.');
    }
}
