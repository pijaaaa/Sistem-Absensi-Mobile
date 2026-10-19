<?php

namespace App\Support;

use App\Models\AuditLog;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;

class AuditLogger
{
    /**
     * Record an audit log entry.
     *
     * @param  array<string, mixed>|null  $old
     * @param  array<string, mixed>|null  $new
     */
    public static function record(string $action, ?Model $entity = null, ?array $old = null, ?array $new = null): AuditLog
    {
        return AuditLog::create([
            'actor_id' => Auth::id(),
            'action' => $action,
            'entity_type' => $entity ? $entity::class : null,
            'entity_id' => $entity?->getKey(),
            'old_json' => $old,
            'new_json' => $new,
        ]);
    }
}
