<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class AttendanceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'device_uid' => ['required', 'string', 'max:255'],
            'photo' => ['required', 'image', 'max:5120'],
            'face_score_local' => ['nullable', 'numeric', 'between:0,1'],
            'client_uuid' => ['nullable', 'uuid'],
        ];
    }

    public function messages(): array
    {
        return [
            'photo.required' => 'Foto wajah wajib dikirim.',
            'device_uid.required' => 'device_uid wajib dikirim.',
        ];
    }
}
