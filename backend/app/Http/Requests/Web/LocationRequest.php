<?php

namespace App\Http\Requests\Web;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class LocationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('polygon_json'))) {
            $decoded = json_decode($this->input('polygon_json'), true);
            $this->merge(['polygon_json' => is_array($decoded) ? $decoded : null]);
        }
    }

    public function rules(): array
    {
        $mode = $this->input('mode');

        return [
            'name' => ['required', 'string', 'max:100', Rule::unique('work_locations', 'name')->ignore($this->route('location'))],
            'mode' => ['required', Rule::in(['point', 'polygon', 'off'])],
            'lat' => [Rule::requiredIf($mode === 'point'), 'nullable', 'numeric', 'between:-90,90'],
            'lng' => [Rule::requiredIf($mode === 'point'), 'nullable', 'numeric', 'between:-180,180'],
            'radius_m' => [Rule::requiredIf($mode === 'point'), 'nullable', 'integer', 'min:1'],
            'polygon_json' => [Rule::requiredIf($mode === 'polygon'), 'nullable', 'array', 'min:3'],
            'polygon_json.*' => ['array', 'size:2'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama lokasi wajib diisi.',
            'name.unique' => 'Nama lokasi sudah ada.',
            'radius_m.required' => 'Radius wajib diisi untuk mode point.',
            'polygon_json.min' => 'Polygon minimal 3 titik.',
        ];
    }
}
