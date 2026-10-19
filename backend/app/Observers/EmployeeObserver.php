<?php

namespace App\Observers;

use App\Models\Employee;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class EmployeeObserver
{
    public function saving(Employee $employee): void
    {
        $user = $employee->user;

        if (! $user || $user->role->value !== 'manager_department') {
            return;
        }

        if (! $user->is_active || ! $employee->is_active) {
            return;
        }

        $exists = DB::table('employees')
            ->join('users', 'users.id', '=', 'employees.user_id')
            ->where('employees.department_id', $employee->department_id)
            ->where('users.role', 'manager_department')
            ->where('users.is_active', true)
            ->where('employees.is_active', true)
            ->when($employee->id, fn ($q) => $q->where('employees.id', '!=', $employee->id))
            ->exists();

        if ($exists) {
            throw ValidationException::withMessages([
                'department_id' => 'Setiap department hanya boleh punya 1 manager aktif.'],
            );
        }
    }
}
