<?php

namespace Tests\Feature\Api;

use App\Models\Attendance;
use App\Models\Department;
use App\Models\User;
use Carbon\Carbon;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Database\Seeders\ScheduleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class AttendanceApprovalTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    private Department $deptA;

    private Department $deptB;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow(Carbon::create(2026, 10, 19, 8, 0, 0, 'Asia/Jakarta'));
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, ScheduleSeeder::class]);

        $this->deptA = Department::create(['name' => 'A']);
        $this->deptB = Department::create(['name' => 'B']);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function pendingAttendance(User $karyawan): Attendance
    {
        return Attendance::create([
            'employee_id' => $karyawan->employee->id,
            'date' => now()->toDateString(),
            'check_in_at' => now(),
            'is_backup_device' => true,
            'approval_status' => 'pending',
        ]);
    }

    public function test_manager_sees_only_own_department_pending(): void
    {
        $karyawanA = $this->makeEmployeeUser('karyawan', $this->deptA);
        $karyawanB = $this->makeEmployeeUser('karyawan', $this->deptB);
        $this->pendingAttendance($karyawanA);
        $this->pendingAttendance($karyawanB);

        $managerA = $this->makeEmployeeUser('manager_department', $this->deptA);

        $data = $this->actingAs($managerA, 'sanctum')->getJson('/api/attendance-approval')->assertOk()->json('data');

        $this->assertCount(1, $data);
        $this->assertSame($karyawanA->employee->name, $data[0]['employee']);
    }

    public function test_manager_other_department_cannot_approve(): void
    {
        $karyawanA = $this->makeEmployeeUser('karyawan', $this->deptA);
        $attendance = $this->pendingAttendance($karyawanA);
        $managerB = $this->makeEmployeeUser('manager_department', $this->deptB);

        $this->actingAs($managerB, 'sanctum')
            ->postJson("/api/attendance-approval/{$attendance->id}/approve")
            ->assertStatus(403);

        $this->assertSame('pending', $attendance->fresh()->approval_status);
    }

    public function test_manager_same_department_can_approve(): void
    {
        $karyawanA = $this->makeEmployeeUser('karyawan', $this->deptA);
        $attendance = $this->pendingAttendance($karyawanA);
        $managerA = $this->makeEmployeeUser('manager_department', $this->deptA);

        $this->actingAs($managerA, 'sanctum')
            ->postJson("/api/attendance-approval/{$attendance->id}/approve")
            ->assertOk();

        $attendance->refresh();
        $this->assertSame('approved', $attendance->approval_status);
        $this->assertSame($managerA->id, $attendance->approver_id);
    }

    public function test_manager_same_department_can_reject(): void
    {
        $karyawanA = $this->makeEmployeeUser('karyawan', $this->deptA);
        $attendance = $this->pendingAttendance($karyawanA);
        $managerA = $this->makeEmployeeUser('manager_department', $this->deptA);

        $this->actingAs($managerA, 'sanctum')
            ->postJson("/api/attendance-approval/{$attendance->id}/reject")
            ->assertOk();

        $this->assertSame('rejected', $attendance->fresh()->approval_status);
    }

    public function test_karyawan_cannot_access_approval_inbox(): void
    {
        $karyawan = $this->makeEmployeeUser('karyawan', $this->deptA);

        $this->actingAs($karyawan, 'sanctum')->getJson('/api/attendance-approval')->assertStatus(403);
    }
}
