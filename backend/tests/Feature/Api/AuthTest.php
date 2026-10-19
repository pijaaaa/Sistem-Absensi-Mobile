<?php

namespace Tests\Feature\Api;

use App\Models\Department;
use App\Models\Employee;
use App\Models\User;
use App\Models\WorkLocation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    private function makeEmployee(array $userOverrides = [], array $employeeOverrides = []): User
    {
        $location = WorkLocation::create([
            'name' => 'Kantor',
            'mode' => 'point',
            'lat' => -6.2,
            'lng' => 106.8,
            'radius_m' => 100,
        ]);

        $department = Department::create(['name' => 'Teknologi']);

        $user = User::create(array_merge([
            'name' => 'Budi',
            'email' => 'budi@example.com',
            'password' => 'password',
            'role' => 'karyawan',
            'is_active' => true,
        ], $userOverrides));

        Employee::create(array_merge([
            'user_id' => $user->id,
            'nip' => 'KRW-001',
            'name' => $user->name,
            'department_id' => $department->id,
            'work_location_id' => $location->id,
            'is_active' => true,
        ], $employeeOverrides));

        return $user;
    }

    public function test_login_with_email_returns_token(): void
    {
        $this->makeEmployee();

        $response = $this->postJson('/api/auth/login', [
            'login' => 'budi@example.com',
            'password' => 'password',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['token', 'user' => ['id', 'role', 'employee']]]);
    }

    public function test_login_with_nip_returns_token(): void
    {
        $this->makeEmployee();

        $this->postJson('/api/auth/login', [
            'login' => 'KRW-001',
            'password' => 'password',
        ])->assertOk()->assertJsonPath('success', true);
    }

    public function test_login_with_wrong_password_fails_with_consistent_error(): void
    {
        $this->makeEmployee();

        $this->postJson('/api/auth/login', [
            'login' => 'budi@example.com',
            'password' => 'salah',
        ])->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['success', 'message', 'errors' => ['login']]);
    }

    public function test_inactive_user_cannot_login(): void
    {
        $this->makeEmployee(['is_active' => false]);

        $this->postJson('/api/auth/login', [
            'login' => 'budi@example.com',
            'password' => 'password',
        ])->assertStatus(422)->assertJsonPath('success', false);
    }

    public function test_me_requires_authentication(): void
    {
        $this->getJson('/api/me')
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_me_returns_profile_with_relations(): void
    {
        $user = $this->makeEmployee();

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('data.role', 'karyawan')
            ->assertJsonPath('data.employee.nip', 'KRW-001')
            ->assertJsonPath('data.employee.department.name', 'Teknologi')
            ->assertJsonPath('data.employee.work_location.name', 'Kantor');
    }

    public function test_logout_revokes_current_token(): void
    {
        $this->makeEmployee();

        $token = $this->postJson('/api/auth/login', [
            'login' => 'budi@example.com',
            'password' => 'password',
        ])->json('data.token');

        $this->withToken($token)->postJson('/api/auth/logout')->assertOk();

        $this->app['auth']->forgetGuards();
        $this->assertDatabaseCount('personal_access_tokens', 0);

        $this->withToken($token)->getJson('/api/me')->assertStatus(401);
    }
}
