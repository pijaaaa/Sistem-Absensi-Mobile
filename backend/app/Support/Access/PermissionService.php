<?php

namespace App\Support\Access;

use App\Enums\Role;
use App\Models\Permission;
use App\Models\RolePermission;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;

class PermissionService
{
    /** @return array<int, string> */
    public function keysForRole(Role|string $role): array
    {
        $role = $role instanceof Role ? $role->value : $role;

        if ($role === Role::SUPERADMIN->value) {
            return $this->allKeys();
        }

        return Cache::rememberForever("perms:role:$role", fn () => RolePermission::query()
            ->where('role', $role)
            ->whereHas('permission')
            ->join('permissions', 'permissions.id', '=', 'role_permissions.permission_id')
            ->pluck('permissions.key')
            ->all());
    }

    /** @return array<int, string> */
    public function allKeys(): array
    {
        return Cache::rememberForever('perms:all', fn () => Permission::query()
            ->pluck('key')
            ->all());
    }

    public function userHas($user, string $key): bool
    {
        if ($user->isSuperadmin()) {
            return true;
        }

        return in_array($key, $this->keysForRole($user->role), true);
    }

    /**
     * Beri izin pada role. Modul access & menus untuk superadmin dikunci (ignore).
     */
    public function grant(string $role, string $key): void
    {
        if ($this->isLocked($role, $key)) {
            return;
        }

        /** @var Permission $permission */
        $permission = Permission::where('key', $key)->first();

        if ($permission && ! RolePermission::where('role', $role)->where('permission_id', $permission->id)->exists()) {
            RolePermission::create(['role' => $role, 'permission_id' => $permission->id]);
        }

        $this->flushRole($role);
    }

    public function revoke(string $role, string $key): void
    {
        if ($this->isLocked($role, $key)) {
            return;
        }

        $permission = Permission::where('key', $key)->first();

        if ($permission) {
            RolePermission::where('role', $role)->where('permission_id', $permission->id)->delete();
        }

        $this->flushRole($role);
    }

    /** Kunci anti-lockout: superadmin tidak boleh kehilangan izin access/menus. */
    public function isLocked(string $role, string $key): bool
    {
        return $role === Role::SUPERADMIN->value
            && (str_starts_with($key, 'access.') || str_starts_with($key, 'menus.'));
    }

    public function granted(string $role): Collection
    {
        return collect($this->keysForRole($role));
    }

    /** @return array<string, bool> key => granted */
    public function matrix(string $role): array
    {
        $granted = $this->granted($role);

        return collect($this->allKeys())->mapWithKeys(fn (string $k) => [$k => $granted->contains($k)])->all();
    }

    public function flushAll(): void
    {
        // ponytail: coarse flush; per-key invalidation once cache volume matters.
        Cache::flush();
    }

    public function flushRole(string $role): void
    {
        $this->flushAll();
    }
}
