<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Holiday;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class HolidayController extends Controller
{
    public function index(Request $request): View
    {
        $year = (int) $request->input('year', now()->year);
        $holidays = Holiday::whereYear('date', $year)->orderBy('date')->get();

        return view('holidays.index', compact('holidays', 'year'));
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'date' => ['required', 'date', 'unique:holidays,date'],
            'name' => ['required', 'string', 'max:100'],
        ], [
            'date.unique' => 'Tanggal merah ini sudah ada.',
        ]);

        $holiday = Holiday::create($data);
        AuditLogger::record('created', $holiday, null, $holiday->getAttributes());

        return back()->with('status', 'Tanggal merah ditambahkan.');
    }

    public function destroy(Holiday $holiday): RedirectResponse
    {
        $old = $holiday->getAttributes();
        $holiday->delete();
        AuditLogger::record('deleted', $holiday, $old, null);

        return back()->with('status', 'Tanggal merah dihapus.');
    }
}
