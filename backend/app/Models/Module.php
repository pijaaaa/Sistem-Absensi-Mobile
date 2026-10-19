<?php

namespace App\Models;

use App\Enums\PermissionAction;
use App\Enums\Platform;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Module extends Model
{
    protected $fillable = ['key', 'label', 'platform', 'extra_actions', 'sort_order'];

    protected function casts(): array
    {
        return [
            'platform' => Platform::class,
            'extra_actions' => 'array',
        ];
    }

    public function permissions(): HasMany
    {
        return $this->hasMany(Permission::class);
    }

    public function menus(): HasMany
    {
        return $this->hasMany(Menu::class);
    }

    /**
     * Seluruh aksi yang berlaku untuk modul ini (standar + aksi khusus).
     *
     * @return array<int, PermissionAction>
     */
    public function actionList(): array
    {
        $extras = array_map(
            fn (string $a) => PermissionAction::from($a),
            $this->extra_actions ?? []
        );

        return array_merge(PermissionAction::standard(), $extras);
    }
}
