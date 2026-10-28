<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        DB::table('settings')->insertOrIgnore([
            ['key' => 'notif_leave_expiry_dates', 'value' => '11-01,12-15'],
            ['key' => 'notif_leave_expiry_threshold', 'value' => '3'],
            ['key' => 'notif_pending_approval_enabled', 'value' => '1'],
            ['key' => 'notif_retention_days', 'value' => '90'],
            ['key' => 'notif_reminder_checkin_enabled', 'value' => '1'],
            ['key' => 'notif_reminder_checkout_enabled', 'value' => '1'],
            ['key' => 'notif_reminder_forgot_checkout_enabled', 'value' => '1'],
        ]);
    }

    public function down(): void
    {
        DB::table('settings')->whereIn('key', [
            'notif_leave_expiry_dates',
            'notif_leave_expiry_threshold',
            'notif_pending_approval_enabled',
            'notif_retention_days',
            'notif_reminder_checkin_enabled',
            'notif_reminder_checkout_enabled',
            'notif_reminder_forgot_checkout_enabled',
        ])->delete();
    }
};
