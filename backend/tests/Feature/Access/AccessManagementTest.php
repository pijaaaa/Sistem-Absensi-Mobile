<?php

namespace Tests\Feature\Access;

use App\Models\Permission;
use App\Models\RolePermission;
use App\Support\Access\PermissionService;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class AccessManagementTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class]);
    }

    public function test_superadmin_can_open_access_page(): void
    {
        $superadmin = $this->makeUser('superadmin');

        $this->actingAs($superadmin)->get('/access')->assertOk();
    }

    public function test_checking_update_does_not_enable_delete(): void
    {
        $superadmin = $this->makeUser('superadmin');

        $this->actingAs($superadmin)->post('/access', [
            'matrix' => [
                'karyawan' => [
                    'departments.view' => 1,
                    'departments.update' => 1,
                ],
            ],
        ])->assertRedirect(route('access.index'));

        $service = app(PermissionService::class);
        $granted = $service->granted('karyawan');

        $this->assertTrue($granted->contains('departments.update'));
        $this->assertFalse($granted->contains('departments.delete'));
    }

    public function test_superadmin_cannot_revoke_locked_access_permission(): void
    {
        $permission = Permission::where('key', 'access.view')->firstOrFail();
        RolePermission::create(['role' => 'superadmin', 'permission_id' => $permission->id]);

        $superadmin = $this->makeUser('superadmin');

        // Kirim matriks tanpa access.view untuk superadmin.
        $this->actingAs($superadmin)->post('/access', [
            'matrix' => ['superadmin' => ['employees.view' => 1]],
        ]);

        $this->assertDatabaseHas('role_permissions', [
            'role' => 'superadmin',
            'permission_id' => $permission->id,
        ]);
    }

    public function test_permission_changes_are_audited(): void
    {
        $superadmin = $this->makeUser('superadmin');

        $this->actingAs($superadmin)->post('/access', [
            'matrix' => ['karyawan' => ['departments.view' => 1]],
        ]);

        $this->assertDatabaseHas('audit_logs', ['action' => 'access.updated']);
    }
}
