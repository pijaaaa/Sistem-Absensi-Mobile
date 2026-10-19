<?php

namespace Tests\Feature\Api;

use App\Models\Department;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class DepartmentScopeTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class]);
    }

    public function test_requires_view_permission(): void
    {
        $dept = Department::create(['name' => 'A']);
        $manager = $this->makeEmployeeUser('manager_department', $dept);

        $this->actingAs($manager, 'sanctum')
            ->getJson('/api/departments')
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_manager_only_sees_own_department(): void
    {
        $a = Department::create(['name' => 'A']);
        Department::create(['name' => 'B']);
        $manager = $this->makeEmployeeUser('manager_department', $a);
        $this->grant('manager_department', 'departments.view');

        $response = $this->actingAs($manager, 'sanctum')
            ->getJson('/api/departments')
            ->assertOk()
            ->json('data');

        $names = array_column($response, 'name');
        $this->assertSame(['A'], $names);
    }

    public function test_superadmin_sees_all_departments(): void
    {
        Department::create(['name' => 'A']);
        Department::create(['name' => 'B']);
        $superadmin = $this->makeUser('superadmin');

        $data = $this->actingAs($superadmin, 'sanctum')
            ->getJson('/api/departments')
            ->assertOk()
            ->json('data');

        $this->assertCount(2, $data);
    }

    public function test_view_only_role_cannot_create_update_delete(): void
    {
        Route::middleware(['auth:sanctum', 'permission:departments.create'])->post('/_t/dept', fn () => response()->json(['ok' => true]));
        Route::middleware(['auth:sanctum', 'permission:departments.update'])->put('/_t/dept', fn () => response()->json(['ok' => true]));
        Route::middleware(['auth:sanctum', 'permission:departments.delete'])->delete('/_t/dept', fn () => response()->json(['ok' => true]));

        $dept = Department::create(['name' => 'A']);
        $manager = $this->makeEmployeeUser('manager_department', $dept);
        $this->grant('manager_department', 'departments.view');

        $this->actingAs($manager, 'sanctum')->getJson('/api/departments')->assertOk();
        $this->actingAs($manager, 'sanctum')->postJson('/_t/dept')->assertStatus(403);
        $this->actingAs($manager, 'sanctum')->putJson('/_t/dept')->assertStatus(403);
        $this->actingAs($manager, 'sanctum')->deleteJson('/_t/dept')->assertStatus(403);
    }
}
