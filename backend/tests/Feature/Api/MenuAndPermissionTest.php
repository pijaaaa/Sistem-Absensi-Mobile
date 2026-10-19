<?php

namespace Tests\Feature\Api;

use Database\Seeders\MenuSeeder;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class MenuAndPermissionTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, MenuSeeder::class]);
    }

    public function test_karyawan_sees_own_mobile_menus_only(): void
    {
        $karyawan = $this->makeEmployeeUser('karyawan');

        $features = $this->actingAs($karyawan, 'sanctum')
            ->getJson('/api/me/menus')
            ->assertOk()
            ->json('data.*.feature_key');

        $this->assertContains('history', $features);
        $this->assertContains('attendance', $features);
        $this->assertNotContains('approval', $features);
        $this->assertNotContains('team_stats', $features);
    }

    public function test_menu_disappears_when_view_permission_revoked(): void
    {
        $karyawan = $this->makeEmployeeUser('karyawan');

        $before = $this->actingAs($karyawan, 'sanctum')->getJson('/api/me/menus')->json('data.*.feature_key');
        $this->assertContains('history', $before);

        $this->revoke('karyawan', 'history.view');

        $after = $this->actingAs($karyawan, 'sanctum')->getJson('/api/me/menus')->json('data.*.feature_key');
        $this->assertNotContains('history', $after);
    }

    public function test_manager_sees_approval_menu(): void
    {
        $manager = $this->makeEmployeeUser('manager_department');

        $features = $this->actingAs($manager, 'sanctum')->getJson('/api/me/menus')->json('data.*.feature_key');

        $this->assertContains('approval', $features);
        $this->assertContains('team_stats', $features);
    }

    public function test_permissions_endpoint_returns_role_keys(): void
    {
        $karyawan = $this->makeEmployeeUser('karyawan');

        $this->actingAs($karyawan, 'sanctum')
            ->getJson('/api/me/permissions')
            ->assertOk()
            ->assertJsonPath('data.is_superadmin', false)
            ->assertJsonFragment(['leave_requests.create']);
    }

    public function test_superadmin_permissions_include_all(): void
    {
        $superadmin = $this->makeUser('superadmin');

        $data = $this->actingAs($superadmin, 'sanctum')
            ->getJson('/api/me/permissions')
            ->assertOk()
            ->json('data');

        $this->assertTrue($data['is_superadmin']);
        $this->assertContains('access.update', $data['keys']);
        $this->assertContains('menus.delete', $data['keys']);
    }
}
