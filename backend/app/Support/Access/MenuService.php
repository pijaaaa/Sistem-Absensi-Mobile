<?php

namespace App\Support\Access;

use App\Enums\Role;
use App\Models\Menu;
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

        return Cache::rememberForever("menus:$platform:$roleValue", function () use ($roleValue, $platform) {
            $keys = $this->permissions->keysForRole($roleValue);

            return Menu::query()
                ->where('platform', $platform)
                ->where('is_active', true)
                ->with('module')
                ->orderBy('sort_order')
                ->get()
                ->filter(function (Menu $menu) use ($keys) {
                    return in_array($menu->module->key.'.view', $keys, true);
                })
                ->values();
        });
    }

    public function flushAll(): void
    {
        Cache::flush();
    }
}
