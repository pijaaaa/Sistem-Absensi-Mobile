<?php

namespace Tests\Feature\Web;

use App\Models\Department;
use App\Models\Device;
use App\Models\Employee;
use App\Models\Holiday;
use App\Models\Setting;
use App\Models\WorkLocation;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Database\Seeders\ScheduleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class AdminCrudTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, ScheduleSeeder::class]);
    }

    private function superadmin(): void
    {
        $this->actingAs($this->makeUser('superadmin'));
    }

    public function test_department_crud_and_audit(): void
    {
        $this->superadmin();

        $this->post('/departments', ['name' => 'Keuangan'])->assertRedirect(route('departments.index'));
        $department = Department::where('name', 'Keuangan')->firstOrFail();
        $this->assertDatabaseHas('audit_logs', ['action' => 'created', 'entity_type' => Department::class]);

        $this->put('/departments/'.$department->id, ['name' => 'Finance'])->assertRedirect();
        $this->assertSame('Finance', $department->fresh()->name);

        $this->delete('/departments/'.$department->id)->assertRedirect();
        $this->assertDatabaseMissing('departments', ['id' => $department->id]);
    }

    public function test_department_pages_ok(): void
    {
        $this->superadmin();
        $this->get('/departments')->assertOk();
        $this->get('/departments/create')->assertOk();
    }

    public function test_all_admin_pages_render(): void
    {
        $this->superadmin();

        foreach ([
            '/dashboard', '/departments', '/departments/create',
            '/employees', '/employees/create',
            '/locations', '/locations/create',
            '/schedule', '/lateness', '/holidays', '/leave-quota',
            '/settings', '/audit-logs', '/access', '/menus', '/devices', '/leave-requests',
        ] as $path) {
            $this->get($path)->assertOk();
        }
    }

    public function test_superadmin_can_reset_device(): void
    {
        $this->superadmin();
        $department = Department::create(['name' => 'Teknologi']);
        $location = WorkLocation::create(['name' => 'Kantor', 'mode' => 'off']);
        $user = $this->makeUser('karyawan', ['email' => 'dev@example.com']);
        $employee = Employee::create([
            'user_id' => $user->id, 'nip' => 'DEV-1', 'name' => 'D',
            'department_id' => $department->id, 'work_location_id' => $location->id, 'is_active' => true,
        ]);
        $device = Device::create([
            'employee_id' => $employee->id, 'device_uid' => 'uid-1', 'type' => 'primary', 'status' => 'active',
        ]);

        $this->delete('/devices/'.$device->id)->assertRedirect();
        $this->assertDatabaseMissing('devices', ['id' => $device->id]);
        $this->assertDatabaseHas('audit_logs', ['action' => 'device.reset']);
    }

    public function test_employee_creates_user_and_employee(): void
    {
        $this->superadmin();
        $department = Department::create(['name' => 'Teknologi']);
        $location = WorkLocation::create(['name' => 'Kantor', 'mode' => 'off']);

        $this->post('/employees', [
            'name' => 'Budi',
            'email' => 'budi@example.com',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
            'nip' => 'KRW-001',
            'role' => 'karyawan',
            'department_id' => $department->id,
            'work_location_id' => $location->id,
            'is_active' => 1,
        ])->assertRedirect(route('employees.index'));

        $this->assertDatabaseHas('users', ['email' => 'budi@example.com', 'role' => 'karyawan']);
        $this->assertDatabaseHas('employees', ['nip' => 'KRW-001', 'department_id' => $department->id]);
    }

    public function test_employee_duplicate_nip_fails(): void
    {
        $this->superadmin();
        $department = Department::create(['name' => 'Teknologi']);
        $location = WorkLocation::create(['name' => 'Kantor', 'mode' => 'off']);
        $user = $this->makeUser('karyawan', ['email' => 'x@example.com']);
        Employee::create([
            'user_id' => $user->id, 'nip' => 'DUP-1', 'name' => 'X',
            'department_id' => $department->id, 'work_location_id' => $location->id, 'is_active' => true,
        ]);

        $this->post('/employees', [
            'name' => 'Y', 'email' => 'y@example.com',
            'password' => 'secret123', 'password_confirmation' => 'secret123',
            'nip' => 'DUP-1', 'role' => 'karyawan',
            'department_id' => $department->id, 'work_location_id' => $location->id,
        ])->assertSessionHasErrors('nip');
    }

    public function test_location_point_requires_radius(): void
    {
        $this->superadmin();

        $this->post('/locations', ['name' => 'P', 'mode' => 'point'])
            ->assertSessionHasErrors(['lat', 'lng', 'radius_m']);
    }

    public function test_location_polygon_requires_three_points(): void
    {
        $this->superadmin();

        $this->post('/locations', [
            'name' => 'Pol', 'mode' => 'polygon',
            'polygon_json' => json_encode([[0, 0], [0, 1]]),
        ])->assertSessionHasErrors('polygon_json');

        $this->post('/locations', [
            'name' => 'Pol2', 'mode' => 'polygon',
            'polygon_json' => json_encode([[0, 0], [0, 5], [5, 0]]),
        ])->assertRedirect(route('locations.index'));

        $this->assertDatabaseHas('work_locations', ['name' => 'Pol2', 'mode' => 'polygon']);
    }

    public function test_location_off_mode_without_coordinates(): void
    {
        $this->superadmin();

        $this->post('/locations', ['name' => 'Bebas', 'mode' => 'off'])
            ->assertRedirect(route('locations.index'));

        $this->assertDatabaseHas('work_locations', ['name' => 'Bebas', 'mode' => 'off', 'lat' => null]);
    }

    public function test_holiday_create_and_duplicate(): void
    {
        $this->superadmin();

        $this->post('/holidays', ['date' => '2026-12-25', 'name' => 'Natal'])->assertRedirect();
        $this->assertDatabaseHas('holidays', ['date' => '2026-12-25']);

        $this->post('/holidays', ['date' => '2026-12-25', 'name' => 'Natal lagi'])->assertSessionHasErrors('date');
        $this->assertSame(1, Holiday::count());
    }

    public function test_settings_persist_and_cache_invalidated(): void
    {
        $this->superadmin();

        $this->assertSame(3, (int) Setting::get('max_backdated_days', 3));

        $this->post('/settings', ['max_backdated_days' => 7])->assertRedirect();
        $this->assertSame('7', (string) Setting::get('max_backdated_days'));
    }

    public function test_leave_quota_update(): void
    {
        $this->superadmin();
        $department = Department::create(['name' => 'Teknologi']);
        $location = WorkLocation::create(['name' => 'Kantor', 'mode' => 'off']);
        $user = $this->makeUser('karyawan', ['email' => 'k@example.com']);
        $employee = Employee::create([
            'user_id' => $user->id, 'nip' => 'E-1', 'name' => 'K',
            'department_id' => $department->id, 'work_location_id' => $location->id, 'is_active' => true,
        ]);

        $this->post('/leave-quota', [
            'year' => now()->year,
            'default_quota' => 12,
            'quotas' => [$employee->id => 20],
        ])->assertRedirect();

        $this->assertDatabaseHas('leave_balances', ['employee_id' => $employee->id, 'quota' => 20]);
        $this->assertSame('12', (string) Setting::get('leave_quota_default'));
    }

    public function test_audit_log_filter(): void
    {
        $this->superadmin();

        $this->post('/departments', ['name' => 'A']);
        $this->post('/departments', ['name' => 'B']);

        $response = $this->get('/audit-logs?action=created');
        $response->assertOk();
        $response->assertSee('created');
    }
}
