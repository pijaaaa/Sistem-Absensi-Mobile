<?php

namespace App\Http\Requests\Web;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class EmployeeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $employee = $this->route('employee');
        $userId = $employee?->user_id;

        return [
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email', 'max:150', Rule::unique('users', 'email')->ignore($userId)],
            'password' => [$employee ? 'nullable' : 'required', 'confirmed', Password::min(6)],
            'nip' => ['required', 'string', 'max:50', Rule::unique('employees', 'nip')->ignore($employee?->id)],
            'role' => ['required', Rule::in(['karyawan', 'manager_department'])],
            'department_id' => ['required', 'exists:departments,id'],
            'work_location_id' => ['required', 'exists:work_locations,id'],
            'is_active' => ['nullable'],
        ];
    }

    public function messages(): array
    {
        return [
            'password.required' => 'Password wajib diisi untuk karyawan baru.',
            'nip.unique' => 'NIP sudah dipakai.',
            'email.unique' => 'Email sudah dipakai.',
        ];
    }
}
