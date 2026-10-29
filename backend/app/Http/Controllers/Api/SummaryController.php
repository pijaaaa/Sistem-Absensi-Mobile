<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WorkSchedule;
use App\Services\SummaryService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SummaryController extends Controller
{
    public function __construct(private SummaryService $summary) {}

    public function self(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Profil karyawan tidak ditemukan.', 'errors' => (object) []], 422);
        }

        $year = (int) $request->input('year', now()->year);
        $month = (int) $request->input('month', now()->month);

        if ($month < 1 || $month > 12) {
            return response()->json(['success' => false, 'message' => 'Bulan tidak valid.', 'errors' => (object) []], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $this->summary->monthly($employee, $year, $month),
        ]);
    }

    public function team(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Profil karyawan tidak ditemukan.', 'errors' => (object) []], 422);
        }

        $day = Carbon::now(WorkSchedule::current()?->timezone ?? config('app.timezone'));

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $this->summary->teamStats($employee, $day),
        ]);
    }

    public function logs(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;
        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Profil karyawan tidak ditemukan.', 'errors' => (object) []], 422);
        }

        $attendances = $employee->attendances()
            ->orderBy('date', 'desc')
            ->limit(10)
            ->get();

        $items = [];
        foreach ($attendances as $att) {
            if ($att->check_out_at) {
                $items[] = [
                    'date' => $att->date?->format('d M Y') ?? (is_string($att->date) ? $att->date : now()->format('d M Y')),
                    'status' => 'Pulang',
                    'time' => $att->check_out_at?->format('H:i') ?? '',
                    'type' => 'present',
                    'is_checkout' => true,
                ];
            }
            if ($att->check_in_at) {
                $isLate = ($att->late_minutes ?? 0) > 0;
                $items[] = [
                    'date' => $att->date?->format('d M Y') ?? (is_string($att->date) ? $att->date : now()->format('d M Y')),
                    'status' => $isLate ? "Telat {$att->late_minutes}m" : 'Masuk',
                    'time' => $att->check_in_at?->format('H:i') ?? '',
                    'type' => $isLate ? 'lateYellow' : 'present',
                    'is_checkout' => false,
                ];
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $items,
        ]);
    }
}
