<?php

namespace Tests\Feature;

use App\Models\Department;
use App\Models\Employee;
use App\Models\User;
use App\Models\WorkLocation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class ManagerPerDepartmentTest extends TestCase
{
    use RefreshDatabase;

    private WorkLocation $location;

    private Department $department;

    protected function setUp(): void
    {
        parent::setUp();

        $this->location = WorkLocation::create([
            'name' => 'Kantor',
            'mode' => 'off',
        ]);

        $this->department = Department::create(['name' => 'Teknologi']);
    }

    private function makeManager(string $email, string $nip, Department $department): Employee
    {
        $user = User::create([
            'name' => $email,
            'email' => $email,
            'password' => 'password',
            'role' => 'manager_department',
            'is_active' => true,
        ]);

        return Employee::create([
            'user_id' => $user->id,
            'nip' => $nip,
            'name' => $email,
            'department_id' => $department->id,
            'work_location_id' => $this->location->id,
            'is_active' => true,
        ]);
    }

    public function test_second_active_manager_in_same_department_is_rejected(): void
    {
        $this->makeManager('a@example.com', 'MGR-1', $this->department);

        $this->expectException(ValidationException::class);

        $this->makeManager('b@example.com', 'MGR-2', $this->department);
    }

    public function test_manager_in_different_department_is_allowed(): void
    {
        $this->makeManager('a@example.com', 'MGR-1', $this->department);

        $other = Department::create(['name' => 'Keuangan']);
        $employee = $this->makeManager('b@example.com', 'MGR-2', $other);

        $this->assertDatabaseHas('employees', ['id' => $employee->id]);
    }
}
