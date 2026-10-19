<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\WorkSchedule;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ScheduleController extends Controller
{
    public function edit(): View
    {
        $schedule = WorkSchedule::current() ?? new WorkSchedule([
            'work_days' => [1, 2, 3, 4, 5],
            'start_time' => '08:00',
            'end_time' => '17:00',
            'timezone' => 'Asia/Jakarta',
        ]);

        return view('schedule.edit', compact('schedule'));
    }

    public function update(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'work_days' => ['required', 'array', 'min:1'],
            'work_days.*' => ['integer', 'between:0,6'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
            'timezone' => ['required', 'string', 'timezone'],
        ], [
            'work_days.required' => 'Pilih minimal satu hari kerja.',
            'end_time.after' => 'Jam pulang harus setelah jam masuk.',
        ]);

        $schedule = WorkSchedule::current();
        $old = $schedule?->getAttributes();

        if ($schedule) {
            $schedule->update($data);
        } else {
            $schedule = WorkSchedule::create($data);
        }

        AuditLogger::record('schedule.updated', $schedule, $old, $schedule->getChanges());

        return redirect()->route('schedule.index')->with('status', 'Jadwal kerja disimpan.');
    }
}
