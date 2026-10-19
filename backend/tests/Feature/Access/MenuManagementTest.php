<?php

namespace Tests\Feature\Access;

use App\Models\Menu;
use Database\Seeders\MenuSeeder;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class MenuManagementTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, MenuSeeder::class]);
    }

    public function test_superadmin_can_open_menu_page(): void
    {
        $superadmin = $this->makeUser('superadmin');

        $this->actingAs($superadmin)->get('/menus')->assertOk();
    }

    public function test_menu_label_and_order_can_be_changed(): void
    {
        $superadmin = $this->makeUser('superadmin');
        $menu = Menu::where('platform', 'web')->where('module_id', function ($q) {
            $q->select('id')->from('modules')->where('key', 'employees');
        })->firstOrFail();

        $this->actingAs($superadmin)->post('/menus', [
            'menus' => [
                $menu->id => ['label' => 'Pegawai', 'icon' => 'users', 'sort_order' => 9, 'is_active' => 1],
            ],
        ])->assertRedirect(route('menus.index'));

        $menu->refresh();
        $this->assertSame('Pegawai', $menu->label);
        $this->assertSame(9, $menu->sort_order);
    }

    public function test_locked_menu_cannot_be_deactivated(): void
    {
        $superadmin = $this->makeUser('superadmin');
        $menu = Menu::where('is_locked', true)->firstOrFail();

        $this->actingAs($superadmin)->post('/menus', [
            'menus' => [
                $menu->id => ['label' => $menu->label, 'icon' => $menu->icon, 'sort_order' => 1],
            ],
        ]);

        $this->assertTrue($menu->refresh()->is_active);
    }
}
