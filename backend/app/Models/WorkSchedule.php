<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkSchedule extends Model
{
    protected $fillable = ['work_days', 'start_time', 'end_time', 'timezone'];

    protected function casts(): array
    {
        return [
            'work_days' => 'array',
        ];
    }

    public static function current(): ?self
    {
        return static::query()->first();
    }
}
