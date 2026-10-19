<?php

namespace Tests\Feature\Api;

use App\Models\Department;
use App\Models\LeaveRequest;
use App\Models\PushToken;
use Carbon\Carbon;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Database\Seeders\ScheduleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class NotificationTest extends TestCase
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

    public function test_register_token(): void
    {
        $user = $this->makeEmployeeUser('karyawan', $this->deptA);

        $this->actingAs($user, 'sanctum')->postJson('/api/push-tokens', [
            'token' => 'tok-abc', 'platform' => 'android',
        ])->assertOk();

        $this->assertDatabaseHas('push_tokens', ['user_id' => $user->id, 'token' => 'tok-abc']);
    }

    public function test_leave_submit_notifies_manager(): void
    {
        Http::fake(); // FCM tanpa key -> dilewati; pastikan tidak error
        $karyawan = $this->makeEmployeeUser('karyawan', $this->deptA);
        $manager = $this->makeEmployeeUser('manager_department', $this->deptA);

        $this->actingAs($karyawan, 'sanctum')->postJson('/api/leave-requests', [
            'type' => 'izin', 'start_date' => '2026-10-19', 'end_date' => '2026-10-19',
        ])->assertStatus(201);

        $this->assertDatabaseHas('notifications', ['user_id' => $manager->id]);
    }

    public function test_approval_notifies_requester(): void
    {
        Http::fake();
        $karyawan = $this->makeEmployeeUser('karyawan', $this->deptA);
        $manager = $this->makeEmployeeUser('manager_department', $this->deptA);

        $leave = LeaveRequest::create([
            'employee_id' => $karyawan->employee->id,
            'type' => 'izin', 'start_date' => '2026-10-19', 'end_date' => '2026-10-19', 'status' => 'pending',
        ]);

        $this->actingAs($manager, 'sanctum')->postJson("/api/leave-approval/{$leave->id}/approve")->assertOk();

        $this->assertDatabaseHas('notifications', ['user_id' => $karyawan->id]);
    }

    public function test_notifications_list_and_mark_read(): void
    {
        Http::fake();
        $user = $this->makeEmployeeUser('karyawan', $this->deptA);
        PushToken::create(['user_id' => $user->id, 'token' => 't1', 'platform' => 'android']);

        $notification = $user->appNotifications()->create(['title' => 'Halo', 'body' => 'Pesan']);

        $list = $this->actingAs($user, 'sanctum')->getJson('/api/notifications')->assertOk()->json('data');
        $this->assertCount(1, $list);
        $this->assertNull($list[0]['read_at']);

        $this->actingAs($user, 'sanctum')->postJson("/api/notifications/{$notification->id}/read")->assertOk();
        $this->assertNotNull($notification->fresh()->read_at);

        $this->actingAs($user, 'sanctum')->postJson('/api/notifications/read-all')->assertOk();
    }

    public function test_cannot_mark_other_user_notification(): void
    {
        Http::fake();
        $owner = $this->makeEmployeeUser('karyawan', $this->deptA);
        $other = $this->makeEmployeeUser('karyawan', $this->deptA);
        $notification = $owner->appNotifications()->create(['title' => 'x', 'body' => 'y']);

        $this->actingAs($other, 'sanctum')->postJson("/api/notifications/{$notification->id}/read")->assertStatus(403);
    }
}
