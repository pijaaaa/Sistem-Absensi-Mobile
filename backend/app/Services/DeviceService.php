<?php

namespace App\Services;

use App\Models\Device;
use App\Models\Employee;
use Illuminate\Validation\ValidationException;

class DeviceService
{
    /**
     * Saat login: device pertama menjadi primary. Device yang belum dikenal
     * tidak otomatis terdaftar (harus daftar cadangan secara eksplisit).
     */
    public function bindOnLogin(Employee $employee, string $deviceUid, ?string $name = null): ?Device
    {
        $existing = $employee->devices()->where('device_uid', $deviceUid)->first();

        if ($existing) {
            return $existing;
        }

        if ($employee->devices()->where('status', 'active')->doesntExist()) {
            return $employee->devices()->create([
                'device_uid' => $deviceUid,
                'name' => $name,
                'type' => 'primary',
                'status' => 'active',
                'registered_at' => now(),
            ]);
        }

        return null;
    }

    public function registerBackup(Employee $employee, string $deviceUid, ?string $name = null): Device
    {
        $existing = $employee->devices()->where('device_uid', $deviceUid)->first();

        if ($existing) {
            return $existing;
        }

        $hasBackup = $employee->devices()->where('type', 'backup')->where('status', 'active')->exists();

        if ($hasBackup) {
            throw ValidationException::withMessages([
                'device_uid' => 'Device cadangan sudah terdaftar (maksimal 1).',
            ]);
        }

        return $employee->devices()->create([
            'device_uid' => $deviceUid,
            'name' => $name,
            'type' => 'backup',
            'status' => 'active',
            'registered_at' => now(),
        ]);
    }

    /**
     * Device yang boleh dipakai absen: harus terdaftar & aktif milik karyawan.
     */
    public function resolveForAttendance(Employee $employee, string $deviceUid): Device
    {
        $device = $employee->devices()
            ->where('device_uid', $deviceUid)
            ->where('status', 'active')
            ->first();

        if (! $device) {
            throw ValidationException::withMessages([
                'device_uid' => 'Device tidak terdaftar. Daftarkan device utama/cadangan dulu.',
            ]);
        }

        return $device;
    }
}
