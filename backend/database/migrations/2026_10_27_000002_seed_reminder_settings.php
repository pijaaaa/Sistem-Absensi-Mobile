<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $defaults = [
            ['key' => 'notif_reminder_enabled', 'value' => '1', 'label' => 'Pengingat absensi aktif'],
            ['key' => 'notif_reminder_checkin_enabled', 'value' => '1', 'label' => 'Reminder masuk'],
            ['key' => 'notif_reminder_checkin_offset', 'value' => '15', 'label' => 'Offset reminder masuk (menit)'],
            ['key' => 'notif_reminder_checkout_enabled', 'value' => '1', 'label' => 'Reminder pulang'],
            ['key' => 'notif_reminder_checkout_offset', 'value' => '15', 'label' => 'Offset reminder pulang (menit)'],
            ['key' => 'notif_reminder_forgot_checkout_enabled', 'value' => '1', 'label' => 'Pengingat lupa pulang'],
            ['key' => 'notif_reminder_forgot_checkout_after', 'value' => '30', 'label' => 'Jeda lupa pulang (menit)'],
            ['key' => 'notif_summary_enabled', 'value' => '1', 'label' => 'Ringkasan harian manager'],
            ['key' => 'notif_summary_hour', 'value' => '9', 'label' => 'Jam ringkasan manager'],
            ['key' => 'notif_summary_minute', 'value' => '0', 'label' => 'Menit ringkasan manager'],
            ['key' => 'notif_retention_days', 'value' => '90', 'label' => 'Retensi notifikasi (hari)'],
        ];

        foreach ($defaults as $d) {
            DB::table('settings')->insertOrIgnore($d);
        }
    }

    public function down(): void
    {
        DB::table('settings')->whereIn('key', [
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
        ])->delete();
    }
};
