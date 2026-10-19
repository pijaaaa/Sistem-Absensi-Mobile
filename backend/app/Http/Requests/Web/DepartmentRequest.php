<?php

namespace App\Http\Requests\Web;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class DepartmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $id = $this->route('department');

        return [
            'name' => ['required', 'string', 'max:100', Rule::unique('departments', 'name')->ignore($id)],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama department wajib diisi.',
            'name.unique' => 'Department sudah ada.',
        ];
    }
}
