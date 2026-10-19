<?php

namespace Tests\Feature\Web;

use App\Models\Department;
use App\Models\LeaveRequest;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Database\Seeders\ScheduleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class LeaveApprovalTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, ScheduleSeeder::class]);
    }

    public function test_superadmin_approves_manager_request(): void
    {
        $superadmin = $this->makeUser('superadmin');
        $manager = $this->makeEmployeeUser('manager_department', Department::create(['name' => 'A']));

        $leave = LeaveRequest::create([
            'employee_id' => $manager->employee->id,
            'type' => 'izin', 'start_date' => '2026-10-19', 'end_date' => '2026-10-19', 'status' => 'pending',
        ]);

        $this->actingAs($superadmin)->get('/leave-requests')->assertOk()->assertSee($manager->name);

        $this->actingAs($superadmin)->post("/leave-requests/{$leave->id}/approve")->assertRedirect();
        $this->assertSame('approved', $leave->fresh()->status);
        $this->assertDatabaseHas('audit_logs', ['action' => 'leave.approved']);
    }

    public function test_karyawan_request_not_shown_in_manager_approval_page(): void
    {
        $superadmin = $this->makeUser('superadmin');
        $karyawan = $this->makeEmployeeUser('karyawan', Department::create(['name' => 'A']));

        LeaveRequest::create([
            'employee_id' => $karyawan->employee->id,
            'type' => 'izin', 'start_date' => '2026-10-19', 'end_date' => '2026-10-19', 'status' => 'pending',
        ]);

        $this->actingAs($superadmin)->get('/leave-requests')->assertOk()->assertDontSee($karyawan->name);
    }
}
