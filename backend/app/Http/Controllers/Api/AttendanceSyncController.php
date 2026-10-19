<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\OfflineSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AttendanceSyncController extends Controller
{
    public function __construct(private OfflineSyncService $sync) {}

    public function serverTime(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $this->sync->serverTime(),
        ]);
    }

    public function sync(Request $request): JsonResponse
    {
        $data = $request->validate([
            'anchor' => ['required', 'array'],
            'anchor.server_time' => ['required', 'date'],
            'anchor.elapsed_realtime' => ['required', 'integer'],
            'anchor.boot_count' => ['required', 'integer'],
            'boot_count' => ['required', 'integer'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.client_uuid' => ['required', 'uuid'],
            'items.*.type' => ['required', 'in:in,out'],
            'items.*.lat' => ['required', 'numeric', 'between:-90,90'],
            'items.*.lng' => ['required', 'numeric', 'between:-180,180'],
            'items.*.elapsed_realtime' => ['required', 'integer'],
            'items.*.device_uid' => ['required', 'string', 'max:255'],
            'items.*.face_score_local' => ['nullable', 'numeric', 'between:0,1'],
            'items.*.photo' => ['nullable', 'string'],
        ]);

        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Profil karyawan tidak ditemukan.', 'errors' => (object) []], 422);
        }

        $results = $this->sync->sync($employee, $data);

        return response()->json([
            'success' => true,
            'message' => 'Sinkronisasi selesai.',
            'data' => $results,
        ]);
    }
}
