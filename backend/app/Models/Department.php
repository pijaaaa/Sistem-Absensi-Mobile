<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Department extends Model
{
    protected $fillable = ['name'];

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class);
    }

    public function manager(): HasOne
    {
        return $this->hasOne(Employee::class)->whereHas('user', fn ($q) => $q->where('role', 'manager_department'));
    }
}
