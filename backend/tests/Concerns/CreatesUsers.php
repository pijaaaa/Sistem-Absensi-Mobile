<?php

namespace Tests\Concerns;

use App\Models\Department;
use App\Models\Employee;
use App\Models\User;
use App\Models\WorkLocation;
use App\Support\Access\PermissionService;

trait CreatesUsers
{
    protected function makeUser(string $role, array $overrides = []): User
    {
        return User::create(array_merge([
            'name' => ucfirst($role),
            'email' => $role.'-'.uniqid().'@example.com',
            'password' => 'password',
            'role' => $role,
            'is_active' => true,
        ], $overrides));
    }

    protected function makeEmployeeUser(string $role, ?Department $department = null, array $overrides = []): User
    {
        $location = WorkLocation::firstOrCreate(['name' => 'Kantor'], ['mode' => 'off']);
        $department ??= Department::firstOrCreate(['name' => 'Dept '.uniqid()]);

        $user = $this->makeUser($role, $overrides);

        Employee::create([
            'user_id' => $user->id,
            'nip' => 'NIP-'.uniqid(),
            'name' => $user->name,
            'department_id' => $department->id,
            'work_location_id' => $location->id,
            'is_active' => true,
        ]);

        return $user->fresh('employee');
    }

    protected function grant(string $role, string ...$keys): void
    {
        $service = app(PermissionService::class);
        foreach ($keys as $key) {
            $service->grant($role, $key);
        }
    }

    protected function revoke(string $role, string ...$keys): void
    {
        $service = app(PermissionService::class);
        foreach ($keys as $key) {
            $service->revoke($role, $key);
        }
    }
}
