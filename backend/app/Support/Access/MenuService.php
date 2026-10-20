<?php

namespace App\Support\Access;

use App\Enums\Role;
use App\Models\Menu;
use App\Models\Module;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;

class MenuService
{
    public function __construct(private PermissionService $permissions) {}

    /**
     * Menu aktif untuk suatu role pada suatu platform, disaring izin view modulnya.
     * Menu tampil jika is_active DAN role punya izin "view" pada modul menu tsb.
     *
     * @return Collection<int, Menu>
     */
    public function forRole(Role|string $role, string $platform): Collection
    {
        $roleValue = $role instanceof Role ? $role->value : $role;

        // ponytail: cache primitif, bukan model — hindari __PHP_Incomplete_Class saat kelas berubah.
        $rows = Cache::rememberForever("menus:$platform:$roleValue", function () use ($roleValue, $platform) {
            $keys = $this->permissions->keysForRole($roleValue);

            return Menu::query()
                ->where('platform', $platform)
                ->where('is_active', true)
                ->with('module')
                ->orderBy('sort_order')
                ->get()
                ->filter(fn (Menu $menu) => in_array($menu->module->key.'.view', $keys, true))
                ->map(fn (Menu $menu) => $menu->getAttributes() + ['module_key' => $menu->module->key])
                ->values()
                ->all();
        });

        return (new Collection($rows))->map(function (array $row) {
            $menu = (new Menu)->newFromBuilder($row);
            $menu->setRelation('module', (new Module)->newFromBuilder(['key' => $row['module_key']]));

            return $menu;
        });
    }

    public function flushAll(): void
    {
        Cache::flush();
    }
}
