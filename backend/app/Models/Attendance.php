<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Attendance extends Model
{
    protected $fillable = [
        'employee_id', 'date', 'check_in_at', 'check_out_at',
        'in_lat', 'in_lng', 'out_lat', 'out_lng', 'location_id',
        'late_minutes', 'late_level', 'early_leave_minutes',
        'is_dinas', 'is_offline', 'time_trust', 'client_uuid',
        'device_id', 'is_backup_device', 'approval_status', 'approver_id',
        'face_score_local', 'face_score_server',
        'review_flag', 'review_status', 'review_note',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'check_in_at' => 'datetime',
            'check_out_at' => 'datetime',
            'is_dinas' => 'boolean',
            'is_offline' => 'boolean',
            'is_backup_device' => 'boolean',
            'review_flag' => 'boolean',
            'late_minutes' => 'integer',
            'early_leave_minutes' => 'integer',
            'face_score_local' => 'float',
            'face_score_server' => 'float',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function location(): BelongsTo
    {
        return $this->belongsTo(WorkLocation::class, 'location_id');
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approver_id');
    }

    public function faceCaptures(): HasMany
    {
        return $this->hasMany(FaceCapture::class);
    }
}
