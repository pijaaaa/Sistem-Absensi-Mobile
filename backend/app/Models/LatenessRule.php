<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LatenessRule extends Model
{
    protected $fillable = ['label', 'from_minute', 'to_minute', 'color', 'is_counted_late'];

    protected function casts(): array
    {
        return [
            'from_minute' => 'integer',
            'to_minute' => 'integer',
            'is_counted_late' => 'boolean',
        ];
    }
}
