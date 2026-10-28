<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationPreference extends Model
{
    protected $fillable = ['user_id', 'type', 'enabled'];

    protected function casts(): array
    {
        return ['enabled' => 'boolean'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public static function isEnabled(int $userId, string $type): bool
    {
        $pref = static::where('user_id', $userId)->where('type', $type)->first();

        return $pref ? $pref->enabled : true;
    }

    public static array $toggleableTypes = [
        'reminder_checkin',
        'reminder_checkout',
        'reminder_forgot_checkout',
        'leave_balance_expiring',
        'team_daily_summary',
    ];

    public static array $alwaysOnTypes = [
        'absent_marked',
        'leave_request_new',
        'leave_decision',
        'backup_attendance_request',
        'backup_attendance_decision',
        'pending_approval_digest',
        'device_registered',
        'offline_sync_result',
    ];
}
