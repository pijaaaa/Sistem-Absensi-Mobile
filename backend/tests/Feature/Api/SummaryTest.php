<?php

namespace Tests\Feature\Api;

use App\Models\Attendance;
use App\Models\Department;
use App\Models\LeaveRequest;
use Carbon\Carbon;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Database\Seeders\ScheduleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class SummaryTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    private Department $deptA;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow(Carbon::create(2026, 10, 19, 8, 0, 0, 'Asia/Jakarta'));
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, ScheduleSeeder::class]);
        $this->deptA = Department::create(['name' => 'A']);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_self_summary_counts(): void
    {
        $user = $this->makeEmployeeUser('karyawan', $this->deptA);
        $eid = $user->employee->id;

        Attendance::create(['employee_id' => $eid, 'date' => '2026-10-19', 'check_in_at' => now(), 'late_minutes' => 0, 'late_level' => 'green']);
        Attendance::create(['employee_id' => $eid, 'date' => '2026-10-20', 'check_in_at' => now(), 'late_minutes' => 12, 'late_level' => 'yellow']);
        Attendance::create(['employee_id' => $eid, 'date' => '2026-10-21', 'is_absent' => true]);
        LeaveRequest::create(['employee_id' => $eid, 'type' => 'sakit', 'start_date' => '2026-10-22', 'end_date' => '2026-10-22', 'status' => 'approved']);

        $data = $this->actingAs($user, 'sanctum')
            ->getJson('/api/attendance/summary?year=2026&month=10')
            ->assertOk()
            ->json('data');

        $this->assertSame(2, $data['hadir']);
        $this->assertSame(1, $data['telat']['kuning']);
        $this->assertSame(1, $data['alfa']);
        $this->assertSame(1, $data['sakit']);
        $this->assertIsArray($data['calendar']);
        $this->assertNotEmpty($data['calendar']);
        $this->assertSame(12, $data['total_menit_telat']);
    }

    public function test_team_stats_for_manager(): void
    {
        $manager = $this->makeEmployeeUser('manager_department', $this->deptA);
        $karyawanA = $this->makeEmployeeUser('karyawan', $this->deptA);
        $karyawanB = $this->makeEmployeeUser('karyawan', $this->deptA);

        Attendance::create([
            'employee_id' => $karyawanA->employee->id,
            'date' => now()->toDateString(), 'check_in_at' => now(),
            'late_minutes' => 20, 'late_level' => 'red',
        ]);

        $data = $this->actingAs($manager, 'sanctum')->getJson('/api/team-stats')->assertOk()->json('data');

        $this->assertSame(2, $data['total_karyawan']);
        $this->assertSame(1, $data['hadir']);
        $this->assertSame(1, $data['telat']);
        $this->assertSame(1, $data['belum_absen']);
    }

    public function test_manager_other_department_excluded_from_team_stats(): void
    {
        $managerA = $this->makeEmployeeUser('manager_department', $this->deptA);
        $deptB = Department::create(['name' => 'B']);
        $karyawanB = $this->makeEmployeeUser('karyawan', $deptB);

        Attendance::create([
            'employee_id' => $karyawanB->employee->id,
            'date' => now()->toDateString(), 'check_in_at' => now(),
        ]);

        $data = $this->actingAs($managerA, 'sanctum')->getJson('/api/team-stats')->json('data');

        $this->assertSame(0, $data['total_karyawan']); // dept B tidak ikut tim dept A
    }
}
