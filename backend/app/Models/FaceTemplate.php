<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FaceTemplate extends Model
{
    protected $fillable = ['employee_id', 'embedding', 'model_version'];

    protected function casts(): array
    {
        return [
            'embedding' => 'encrypted:array',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }
}
