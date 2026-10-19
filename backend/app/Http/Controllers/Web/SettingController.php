<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class SettingController extends Controller
{
    public function edit(): View
    {
        $settings = [
            'max_backdated_days' => (int) Setting::get('max_backdated_days', 3),
        ];

        return view('settings.edit', compact('settings'));
    }

    public function update(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'max_backdated_days' => ['required', 'integer', 'min:0', 'max:30'],
        ], [
            'max_backdated_days.required' => 'Batas hari pengajuan mundur wajib diisi.',
        ]);

        $old = Setting::get('max_backdated_days', 3);
        Setting::put('max_backdated_days', $data['max_backdated_days'], 'Batas hari pengajuan mundur');
        AuditLogger::record('settings.updated', null, ['max_backdated_days' => $old], $data);

        return back()->with('status', 'Pengaturan disimpan.');
    }
}
