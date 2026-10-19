<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class Setting extends Model
{
    protected $primaryKey = 'key';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = ['key', 'label', 'value'];

    public static function get(string $key, mixed $default = null): mixed
    {
        $all = Cache::rememberForever('settings:all', fn () => static::query()->pluck('value', 'key')->all());

        return $all[$key] ?? $default;
    }

    public static function put(string $key, mixed $value, ?string $label = null): void
    {
        static::updateOrCreate(['key' => $key], ['value' => $value, 'label' => $label]);
        Cache::forget('settings:all');
    }

    public static function flushCache(): void
    {
        Cache::forget('settings:all');
    }
}
