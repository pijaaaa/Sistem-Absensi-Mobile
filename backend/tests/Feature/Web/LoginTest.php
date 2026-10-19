<?php

namespace Tests\Feature\Web;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LoginTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $role, bool $active = true): User
    {
        return User::create([
            'name' => 'Test',
            'email' => 'user@example.com',
            'password' => 'password',
            'role' => $role,
            'is_active' => $active,
        ]);
    }

    public function test_guest_is_redirected_from_dashboard(): void
    {
        $this->get('/dashboard')->assertRedirect('/login');
    }

    public function test_superadmin_can_login_and_open_dashboard(): void
    {
        $this->makeUser('superadmin');

        $this->post('/login', [
            'email' => 'user@example.com',
            'password' => 'password',
        ])->assertRedirect('/dashboard');

        $this->assertAuthenticated();
        $this->get('/dashboard')->assertOk();
    }

    public function test_manager_cannot_login_to_web_admin(): void
    {
        $this->makeUser('manager_department');

        $this->post('/login', [
            'email' => 'user@example.com',
            'password' => 'password',
        ])->assertSessionHasErrors('email');

        $this->assertGuest();
    }

    public function test_inactive_superadmin_cannot_login(): void
    {
        $this->makeUser('superadmin', active: false);

        $this->post('/login', [
            'email' => 'user@example.com',
            'password' => 'password',
        ])->assertSessionHasErrors('email');

        $this->assertGuest();
    }
}
