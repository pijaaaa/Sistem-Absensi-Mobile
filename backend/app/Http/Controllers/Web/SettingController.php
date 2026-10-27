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
            'notif_reminder_enabled' => (bool) Setting::get('notif_reminder_enabled', 1),
            'notif_reminder_checkin_enabled' => (bool) Setting::get('notif_reminder_checkin_enabled', 1),
            'notif_reminder_checkin_offset' => (int) Setting::get('notif_reminder_checkin_offset', 15),
            'notif_reminder_checkout_enabled' => (bool) Setting::get('notif_reminder_checkout_enabled', 1),
            'notif_reminder_checkout_offset' => (int) Setting::get('notif_reminder_checkout_offset', 15),
            'notif_reminder_forgot_checkout_enabled' => (bool) Setting::get('notif_reminder_forgot_checkout_enabled', 1),
            'notif_reminder_forgot_checkout_after' => (int) Setting::get('notif_reminder_forgot_checkout_after', 30),
            'notif_summary_enabled' => (bool) Setting::get('notif_summary_enabled', 1),
            'notif_summary_hour' => (int) Setting::get('notif_summary_hour', 9),
            'notif_summary_minute' => (int) Setting::get('notif_summary_minute', 0),
            'notif_retention_days' => (int) Setting::get('notif_retention_days', 90),
        ];

        return view('settings.edit', compact('settings'));
    }

    public function update(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'max_backdated_days' => ['required', 'integer', 'min:0', 'max:30'],
            'notif_reminder_enabled' => ['boolean'],
            'notif_reminder_checkin_enabled' => ['boolean'],
            'notif_reminder_checkin_offset' => ['integer', 'min:0', 'max:120'],
            'notif_reminder_checkout_enabled' => ['boolean'],
            'notif_reminder_checkout_offset' => ['integer', 'min:0', 'max:120'],
            'notif_reminder_forgot_checkout_enabled' => ['boolean'],
            'notif_reminder_forgot_checkout_after' => ['integer', 'min:0', 'max:360'],
            'notif_summary_enabled' => ['boolean'],
            'notif_summary_hour' => ['integer', 'min:0', 'max:23'],
            'notif_summary_minute' => ['integer', 'min:0', 'max:59'],
            'notif_retention_days' => ['integer', 'min:1', 'max:365'],
        ], [
            'max_backdated_days.required' => 'Batas hari pengajuan mundur wajib diisi.',
        ]);

        $keys = [
            'max_backdated_days',
            'notif_reminder_enabled',
            'notif_reminder_checkin_enabled',
            'notif_reminder_checkin_offset',
            'notif_reminder_checkout_enabled',
            'notif_reminder_checkout_offset',
            'notif_reminder_forgot_checkout_enabled',
            'notif_reminder_forgot_checkout_after',
            'notif_summary_enabled',
            'notif_summary_hour',
            'notif_summary_minute',
            'notif_retention_days',
        ];
        $labels = [
            'max_backdated_days' => 'Batas hari pengajuan mundur',
            'notif_reminder_enabled' => 'Reminder notifikasi aktif',
            'notif_reminder_checkin_enabled' => 'Reminder masuk',
            'notif_reminder_checkin_offset' => 'Offset reminder masuk (menit)',
            'notif_reminder_checkout_enabled' => 'Reminder pulang',
            'notif_reminder_checkout_offset' => 'Offset reminder pulang (menit)',
            'notif_reminder_forgot_checkout_enabled' => 'Pengingat lupa pulang',
            'notif_reminder_forgot_checkout_after' => 'Jeda lupa pulang (menit)',
            'notif_summary_enabled' => 'Ringkasan harian manager',
            'notif_summary_hour' => 'Jam ringkasan manager',
            'notif_summary_minute' => 'Menit ringkasan manager',
            'notif_retention_days' => 'Retensi notifikasi (hari)',
        ];

        $old = [];
        $new = [];
        foreach ($keys as $key) {
            $old[$key] = Setting::get($key);
            if (array_key_exists($key, $data)) {
                $new[$key] = $data[$key];
                Setting::put($key, $data[$key], $labels[$key]);
            }
        }

        AuditLogger::record('settings.updated', null, $old, $new);

        return back()->with('status', 'Pengaturan disimpan.');
    }
}
