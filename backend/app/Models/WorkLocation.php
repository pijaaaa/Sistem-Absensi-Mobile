<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WorkLocation extends Model
{
    protected $fillable = ['name', 'mode', 'lat', 'lng', 'radius_m', 'polygon_json'];

    protected function casts(): array
    {
        return [
            'lat' => 'float',
            'lng' => 'float',
            'polygon_json' => 'array',
        ];
    }

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class);
    }
}
