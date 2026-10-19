<?php

namespace App\Models\Concerns;

use App\Support\AuditLogger;

trait Auditable
{
    public static function bootAuditable(): void
    {
        static::created(fn ($model) => AuditLogger::record('created', $model, null, $model->getAttributes()));
        static::updated(fn ($model) => AuditLogger::record('updated', $model, $model->getOriginal(), $model->getChanges()));
        static::deleted(fn ($model) => AuditLogger::record('deleted', $model, $model->getAttributes(), null));
    }
}
