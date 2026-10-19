<?php

namespace App\Http\Controllers\Web;

use App\Exports\AttendanceRecapExport;
use App\Http\Controllers\Controller;
use App\Models\Department;
use App\Models\Employee;
use App\Models\WorkLocation;
use App\Services\ReportService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\Response;

class ReportController extends Controller
{
    public function __construct(private ReportService $report) {}

    public function index(Request $request): View
    {
        $filters = $this->filters($request);
        $recap = $this->report->recap($filters);

        return view('reports.index', [
            'recap' => $recap,
            'filters' => $filters,
            'departments' => Department::orderBy('name')->get(),
            'locations' => WorkLocation::orderBy('name')->get(),
            'from' => $this->report->period($filters)[0],
            'to' => $this->report->period($filters)[1],
        ]);
    }

    public function export(Request $request): Response|BinaryFileResponse
    {
        $filters = $this->filters($request);
        $employees = $this->report->all($filters);
        [$from, $to] = $this->report->period($filters);

        if ($request->input('format') === 'pdf') {
            return Pdf::loadView('reports.pdf', compact('employees', 'from', 'to'))
                ->download('rekap-absensi.pdf');
        }

        $rows = $employees->map(fn (Employee $e) => [
            $e->name,
            $e->nip,
            $e->department?->name,
            $e->workLocation?->name,
            $e->stats['hadir'],
            $e->stats['telat'],
            $e->stats['total_menit_telat'],
            $e->stats['alfa'],
            $e->stats['cuti'],
            $e->stats['sakit'],
            $e->stats['izin'],
            $e->stats['dinas'],
        ])->all();

        return Excel::download(new AttendanceRecapExport($rows), 'rekap-absensi.xlsx');
    }

    /**
     * @return array<string, mixed>
     */
    private function filters(Request $request): array
    {
        $validated = $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'department_id' => ['nullable', 'exists:departments,id'],
            'location_id' => ['nullable', 'exists:work_locations,id'],
            'format' => ['nullable', 'in:excel,pdf'],
        ]);

        return collect($validated)->filter(fn ($v) => $v !== null && $v !== '')->all();
    }
}
