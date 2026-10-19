<?php

namespace Tests\Feature\Access;

use App\Models\Attendance;
use App\Models\Department;
use App\Models\LeaveRequest;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class AccessMatrixTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class]);
    }

    public function test_api_role_permission_matrix(): void
    {
        $department = Department::create(['name' => 'A']);
        $karyawan = $this->makeEmployeeUser('karyawan', $department);
        $manager = $this->makeEmployeeUser('manager_department', $department);
        $superadmin = $this->makeUser('superadmin');

        // [uri, karyawan ok, manager ok, superadmin ok]
        // summary/team-stats butuh profil employee; superadmin tidak punya -> skip.
        $matrix = [
            ['/api/me/permissions', true, true, true],
            ['/api/attendance/summary', true, true, false],
            ['/api/attendance-approval', false, true, true],
            ['/api/leave-approval', false, true, true],
            ['/api/team-stats', false, true, false],
        ];

        foreach ($matrix as [$uri, $karyawanOk, $managerOk, $superadminOk]) {
            $this->actingAs($karyawan, 'sanctum')->getJson($uri)
                ->assertStatus($karyawanOk ? 200 : 403);

            $this->actingAs($manager, 'sanctum')->getJson($uri)
                ->assertStatus($managerOk ? 200 : 403);

            if ($superadminOk) {
                $this->actingAs($superadmin, 'sanctum')->getJson($uri)->assertOk();
            }
        }
    }

    public function test_karyawan_cannot_approve_anything(): void
    {
        $department = Department::create(['name' => 'A']);
        $karyawan = $this->makeEmployeeUser('karyawan', $department);

        $leave = LeaveRequest::create([
            'employee_id' => $karyawan->employee->id,
            'type' => 'izin', 'start_date' => '2026-10-19', 'end_date' => '2026-10-19', 'status' => 'pending',
        ]);
        $attendance = Attendance::create([
            'employee_id' => $karyawan->employee->id,
            'date' => '2026-10-19', 'check_in_at' => now(), 'approval_status' => 'pending',
        ]);

        $this->actingAs($karyawan, 'sanctum')->postJson("/api/leave-approval/{$leave->id}/approve")->assertStatus(403);
        $this->actingAs($karyawan, 'sanctum')->postJson("/api/attendance-approval/{$attendance->id}/approve")->assertStatus(403);
    }

    public function test_web_admin_is_superadmin_only(): void
    {
        $department = Department::create(['name' => 'A']);
        $karyawan = $this->makeEmployeeUser('karyawan', $department);
        $manager = $this->makeEmployeeUser('manager_department', $department);

        foreach (['/dashboard', '/reports', '/review', '/access', '/menus'] as $uri) {
            $this->actingAs($karyawan)->get($uri)->assertStatus(403);
            $this->actingAs($manager)->get($uri)->assertStatus(403);
            $this->actingAs($this->makeUser('superadmin'))->get($uri)->assertOk();
        }
    }

    public function test_unauthenticated_api_returns_401(): void
    {
        $this->getJson('/api/me')->assertStatus(401);
        $this->getJson('/api/leave-approval')->assertStatus(401);
        $this->postJson('/api/attendance/check-in')->assertStatus(401);
    }
}
