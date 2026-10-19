<?php

namespace Database\Seeders;

use App\Models\Permission;
use App\Models\RolePermission;
use Illuminate\Database\Seeder;

class RolePermissionSeeder extends Seeder
{
    /**
     * Hak akses bawaan. Superadmin selalu semua izin (implisit, tidak disimpan).
     */
    private const DEFAULTS = [
        'karyawan' => [
            'home', 'attendance', 'history', 'profile', 'notifications',
        ],
        'manager_department' => [
            'home', 'attendance', 'history', 'profile', 'notifications', 'team_stats',
        ],
    ];

    private const EXTRA = [
        'karyawan' => ['leave_requests.view', 'leave_requests.create', 'attendance.create'],
        'manager_department' => [
            'leave_requests.view', 'leave_requests.create', 'leave_requests.approve',
            'attendance.create',
            'attendance_approval.view', 'attendance_approval.approve',
        ],
    ];

    public function run(): void
    {
        foreach (self::DEFAULTS as $role => $moduleKeys) {
            $keys = [];

            foreach ($moduleKeys as $moduleKey) {
                $keys[] = $moduleKey.'.view';
            }

            $keys = array_merge($keys, self::EXTRA[$role] ?? []);

            foreach ($keys as $key) {
                $permission = Permission::where('key', $key)->first();

                if ($permission) {
                    RolePermission::firstOrCreate([
                        'role' => $role,
                        'permission_id' => $permission->id,
                    ]);
                }
            }
        }
    }
}
