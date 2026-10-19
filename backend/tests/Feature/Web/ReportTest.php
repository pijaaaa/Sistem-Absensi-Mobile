<?php

namespace Tests\Feature\Web;

use App\Models\Attendance;
use App\Models\Department;
use App\Models\Employee;
use App\Models\WorkLocation;
use Carbon\Carbon;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Database\Seeders\ScheduleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow(Carbon::create(2026, 10, 19, 10, 0, 0, 'Asia/Jakarta'));
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, ScheduleSeeder::class]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function employeeWithAttendance(): Employee
    {
        $department = Department::create(['name' => 'Teknologi']);
        $location = WorkLocation::create(['name' => 'Kantor', 'mode' => 'off']);
        $user = $this->makeUser('karyawan', ['email' => 'r@example.com', 'name' => 'Rina']);
        $employee = Employee::create([
            'user_id' => $user->id, 'nip' => 'R-1', 'name' => 'Rina',
            'department_id' => $department->id, 'work_location_id' => $location->id, 'is_active' => true,
        ]);

        Attendance::create([
            'employee_id' => $employee->id, 'date' => '2026-10-19',
            'check_in_at' => now(), 'late_minutes' => 10, 'late_level' => 'yellow',
        ]);
        Attendance::create([
            'employee_id' => $employee->id, 'date' => '2026-10-20', 'is_absent' => true,
        ]);

        return $employee;
    }

    public function test_report_page_renders(): void
    {
        $this->employeeWithAttendance();
        $this->actingAs($this->makeUser('superadmin'));

        $this->get('/reports?from=2026-10-01&to=2026-10-31')
            ->assertOk()
            ->assertSee('Rina');
    }

    public function test_export_excel(): void
    {
        $this->employeeWithAttendance();
        $this->actingAs($this->makeUser('superadmin'));

        $response = $this->get('/reports/export?format=excel&from=2026-10-01&to=2026-10-31');
        $response->assertOk();
        $this->assertStringContainsString('spreadsheetml', (string) $response->headers->get('content-type'));
    }

    public function test_export_pdf(): void
    {
        $this->employeeWithAttendance();
        $this->actingAs($this->makeUser('superadmin'));

        $response = $this->get('/reports/export?format=pdf&from=2026-10-01&to=2026-10-31');
        $response->assertOk();
        $this->assertStringContainsString('pdf', (string) $response->headers->get('content-type'));
    }

    public function test_dashboard_renders(): void
    {
        $this->employeeWithAttendance();
        $this->actingAs($this->makeUser('superadmin'));

        $this->get('/dashboard')->assertOk()->assertSee('Hadir hari ini');
    }
}
