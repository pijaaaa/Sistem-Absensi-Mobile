<?php

namespace Tests\Feature\Api;

use App\Models\Department;
use App\Models\LeaveBalance;
use App\Models\LeaveRequest;
use App\Models\User;
use Carbon\Carbon;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Database\Seeders\ScheduleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class LeaveRequestTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    private Department $deptA;

    private Department $deptB;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow(Carbon::create(2026, 10, 19, 8, 0, 0, 'Asia/Jakarta')); // Senin
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, ScheduleSeeder::class]);

        $this->deptA = Department::create(['name' => 'A']);
        $this->deptB = Department::create(['name' => 'B']);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function submit(User $user, array $data)
    {
        return $this->actingAs($user, 'sanctum')->postJson('/api/leave-requests', $data);
    }

    public function test_cuti_counts_only_working_days(): void
    {
        $user = $this->makeEmployeeUser('karyawan', $this->deptA);
        $manager = $this->makeEmployeeUser('manager_department', $this->deptA);

        // Jum 23 Okt - Sen 26 Okt -> hanya Jumat & Senin (Sabtu/Minggu diabaikan) = 2 hari.
        $this->submit($user, [
            'type' => 'cuti',
            'start_date' => '2026-10-23',
            'end_date' => '2026-10-26',
        ])->assertStatus(201);

        $leave = LeaveRequest::first();
        $this->assertSame('pending', $leave->status);

        $this->actingAs($manager, 'sanctum')->postJson("/api/leave-approval/{$leave->id}/approve")->assertOk();

        $balance = LeaveBalance::where('employee_id', $user->employee->id)->where('year', 2026)->first();
        $this->assertSame(2, $balance->used);
    }

    public function test_approve_cuti_deducts_balance(): void
    {
        $user = $this->makeEmployeeUser('karyawan', $this->deptA);
        $manager = $this->makeEmployeeUser('manager_department', $this->deptA);

        $leave = LeaveRequest::create([
            'employee_id' => $user->employee->id,
            'type' => 'cuti', 'start_date' => '2026-10-19', 'end_date' => '2026-10-21', 'status' => 'pending',
        ]); // 3 hari kerja

        $this->actingAs($manager, 'sanctum')
            ->postJson("/api/leave-approval/{$leave->id}/approve")
            ->assertOk();

        $balance = LeaveBalance::where('employee_id', $user->employee->id)->where('year', 2026)->first();
        $this->assertSame(3, $balance->used);
        $this->assertSame('approved', $leave->fresh()->status);
    }

    public function test_insufficient_balance_rejected(): void
    {
        $user = $this->makeEmployeeUser('karyawan', $this->deptA);
        LeaveBalance::create(['employee_id' => $user->employee->id, 'year' => 2026, 'quota' => 1, 'used' => 0]);

        // 5 hari kerja (Sen-Jum) > saldo 1.
        $this->submit($user, [
            'type' => 'cuti', 'start_date' => '2026-10-19', 'end_date' => '2026-10-23',
        ])->assertStatus(422)->assertJsonPath('message', 'Validasi gagal.');
    }

    public function test_sakit_does_not_deduct_and_allows_backdate(): void
    {
        $user = $this->makeEmployeeUser('karyawan', $this->deptA);
        $manager = $this->makeEmployeeUser('manager_department', $this->deptA);

        // mundur 2 hari (batas default 3).
        $leave = LeaveRequest::create([
            'employee_id' => $user->employee->id,
            'type' => 'sakit', 'start_date' => '2026-10-17', 'end_date' => '2026-10-17', 'status' => 'pending',
        ]);

        $this->actingAs($manager, 'sanctum')->postJson("/api/leave-approval/{$leave->id}/approve")->assertOk();

        $this->assertNull(LeaveBalance::where('employee_id', $user->employee->id)->first()?->used);
    }

    public function test_izin_beyond_backdate_limit_rejected(): void
    {
        $user = $this->makeEmployeeUser('karyawan', $this->deptA);

        $this->submit($user, [
            'type' => 'izin', 'start_date' => '2026-10-10', 'end_date' => '2026-10-10',
        ])->assertStatus(422);
    }

    public function test_overlapping_request_rejected(): void
    {
        $user = $this->makeEmployeeUser('karyawan', $this->deptA);
        LeaveRequest::create([
            'employee_id' => $user->employee->id,
            'type' => 'cuti', 'start_date' => '2026-10-19', 'end_date' => '2026-10-21', 'status' => 'pending',
        ]);

        $this->submit($user, [
            'type' => 'izin', 'start_date' => '2026-10-20', 'end_date' => '2026-10-22',
        ])->assertStatus(422);
    }

    public function test_manager_other_department_cannot_approve(): void
    {
        $karyawanA = $this->makeEmployeeUser('karyawan', $this->deptA);
        $leave = LeaveRequest::create([
            'employee_id' => $karyawanA->employee->id,
            'type' => 'izin', 'start_date' => '2026-10-19', 'end_date' => '2026-10-19', 'status' => 'pending',
        ]);
        $managerB = $this->makeEmployeeUser('manager_department', $this->deptB);

        $this->actingAs($managerB, 'sanctum')->postJson("/api/leave-approval/{$leave->id}/approve")->assertStatus(403);
    }

    public function test_inbox_excludes_manager_own_requests(): void
    {
        $managerA = $this->makeEmployeeUser('manager_department', $this->deptA);
        LeaveRequest::create([
            'employee_id' => $managerA->employee->id,
            'type' => 'cuti', 'start_date' => '2026-10-19', 'end_date' => '2026-10-19', 'status' => 'pending',
        ]);

        $data = $this->actingAs($managerA, 'sanctum')->getJson('/api/leave-approval')->assertOk()->json('data');
        $this->assertCount(0, $data);
    }

    public function test_reject_requires_reason(): void
    {
        $karyawan = $this->makeEmployeeUser('karyawan', $this->deptA);
        $leave = LeaveRequest::create([
            'employee_id' => $karyawan->employee->id,
            'type' => 'izin', 'start_date' => '2026-10-19', 'end_date' => '2026-10-19', 'status' => 'pending',
        ]);
        $manager = $this->makeEmployeeUser('manager_department', $this->deptA);

        $this->actingAs($manager, 'sanctum')->postJson("/api/leave-approval/{$leave->id}/reject", [])
            ->assertStatus(422);
    }

    public function test_balance_endpoint(): void
    {
        $user = $this->makeEmployeeUser('karyawan', $this->deptA);
        LeaveBalance::create(['employee_id' => $user->employee->id, 'year' => 2026, 'quota' => 12, 'used' => 4]);

        $this->actingAs($user, 'sanctum')->getJson('/api/leave-balance')
            ->assertOk()
            ->assertJsonPath('data.remaining', 8);
    }
}
