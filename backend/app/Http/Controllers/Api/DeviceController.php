<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\DeviceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    public function __construct(private DeviceService $devices) {}

    public function index(Request $request): JsonResponse
    {
        $devices = $request->user()->employee?->devices()->get() ?? collect();

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $devices->map(fn ($d) => [
                'id' => $d->id,
                'device_uid' => $d->device_uid,
                'name' => $d->name,
                'type' => $d->type,
                'status' => $d->status,
                'registered_at' => $d->registered_at?->toIso8601String(),
            ]),
        ]);
    }

    public function registerBackup(Request $request): JsonResponse
    {
        $data = $request->validate([
            'device_uid' => ['required', 'string', 'max:255'],
            'name' => ['nullable', 'string', 'max:100'],
        ]);

        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Profil karyawan tidak ditemukan.', 'errors' => (object) []], 422);
        }

        $device = $this->devices->registerBackup($employee, $data['device_uid'], $data['name'] ?? null);

        return response()->json([
            'success' => true,
            'message' => 'Device cadangan terdaftar.',
            'data' => ['id' => $device->id, 'type' => $device->type],
        ]);
    }
}
