<?php

namespace Tests\Feature\Api;

use App\Models\Attendance;
use App\Models\Department;
use App\Models\Device;
use App\Models\FaceTemplate;
use App\Models\User;
use App\Models\WorkLocation;
use Carbon\Carbon;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Database\Seeders\ScheduleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class AttendanceSyncTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    private Department $department;

    private WorkLocation $location;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow(Carbon::create(2026, 10, 19, 8, 0, 0, 'Asia/Jakarta'));
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, ScheduleSeeder::class]);

        $this->department = Department::create(['name' => 'Teknologi']);
        $this->location = WorkLocation::create([
            'name' => 'Kantor', 'mode' => 'point', 'lat' => -6.2, 'lng' => 106.8, 'radius_m' => 200,
        ]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function employeeWithFace(string $deviceUid = 'dev-A', string $deviceType = 'primary'): User
    {
        $user = $this->makeEmployeeUser('karyawan', $this->department);
        $user->employee->update(['work_location_id' => $this->location->id]);

        FaceTemplate::create([
            'employee_id' => $user->employee->id,
            'embedding' => array_fill(0, 128, 0.1),
            'model_version' => 'sface-2021dec+yunet-2023mar',
        ]);

        Device::create([
            'employee_id' => $user->employee->id, 'device_uid' => $deviceUid,
            'type' => $deviceType, 'status' => 'active', 'registered_at' => now(),
        ]);

        return $user->fresh('employee');
    }

    private function fakeVerify(bool $match = true): void
    {
        Http::fake(['*/verify' => Http::response([
            'model_version' => 'sface-2021dec+yunet-2023mar',
            'score' => $match ? 0.9 : 0.1, 'threshold' => 0.363, 'match' => $match,
        ], 200)]);
    }

    private function item(string $uuid, int $elapsed, string $uid = 'dev-A', string $type = 'in'): array
    {
        return [
            'client_uuid' => $uuid,
            'type' => $type,
            'lat' => -6.2,
            'lng' => 106.8,
            'elapsed_realtime' => $elapsed,
            'device_uid' => $uid,
            'face_score_local' => 0.95,
            'photo' => base64_encode(str_repeat('a', 64)),
        ];
    }

    private function anchor(int $elapsedAnchor = 1000, int $bootCount = 1): array
    {
        return [
            'server_time' => '2026-10-19T08:00:00+07:00',
            'elapsed_realtime' => $elapsedAnchor,
            'boot_count' => $bootCount,
        ];
    }

    public function test_server_time_endpoint(): void
    {
        $user = $this->employeeWithFace();

        $this->actingAs($user, 'sanctum')->getJson('/api/time')
            ->assertOk()
            ->assertJsonPath('data.timezone', 'Asia/Jakarta')
            ->assertJsonStructure(['data' => ['server_time', 'timezone']]);
    }

    public function test_sync_recomputes_time_and_lateness(): void
    {
        $this->fakeVerify();
        $user = $this->employeeWithFace();

        $uuid = fake()->uuid();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/attendance/sync', [
            'anchor' => $this->anchor(),
            'boot_count' => 1,
            'items' => [$this->item($uuid, 1000 + 600000)], // +10 menit -> 08:10
        ])->assertOk();

        $this->assertSame('created', $response->json('data.0.status'));

        $attendance = Attendance::where('client_uuid', $uuid)->firstOrFail();
        $this->assertSame(10, $attendance->late_minutes);
        $this->assertSame('yellow', $attendance->late_level);
        $this->assertTrue($attendance->is_offline);
        $this->assertFalse($attendance->review_flag);
    }

    public function test_double_send_is_idempotent(): void
    {
        $this->fakeVerify();
        $user = $this->employeeWithFace();
        $uuid = fake()->uuid();
        $payload = [
            'anchor' => $this->anchor(),
            'boot_count' => 1,
            'items' => [$this->item($uuid, 2000)],
        ];

        $this->actingAs($user, 'sanctum')->postJson('/api/attendance/sync', $payload)->assertOk();
        $second = $this->actingAs($user, 'sanctum')->postJson('/api/attendance/sync', $payload)->assertOk();

        $this->assertSame('duplicate', $second->json('data.0.status'));
        $this->assertDatabaseCount('attendances', 1);
    }

    public function test_boot_count_change_marks_suspect_and_review(): void
    {
        $this->fakeVerify();
        $user = $this->employeeWithFace();
        $uuid = fake()->uuid();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/attendance/sync', [
            'anchor' => $this->anchor(1000, 1),
            'boot_count' => 2, // HP restart
            'items' => [$this->item($uuid, 2000)],
        ])->assertOk();

        $this->assertTrue($response->json('data.0.review_flag'));
        $this->assertSame('suspect', $response->json('data.0.time_trust'));
        $this->assertSame('suspect', Attendance::where('client_uuid', $uuid)->first()->time_trust);
    }

    public function test_face_mismatch_sets_review_not_reject(): void
    {
        $this->fakeVerify(false);
        $user = $this->employeeWithFace();
        $uuid = fake()->uuid();

        $this->actingAs($user, 'sanctum')->postJson('/api/attendance/sync', [
            'anchor' => $this->anchor(),
            'boot_count' => 1,
            'items' => [$this->item($uuid, 2000)],
        ])->assertOk()->assertJsonPath('data.0.review_flag', true);

        $this->assertDatabaseCount('attendances', 1); // tidak ditolak otomatis
    }

    public function test_batch_mixed_creates_and_skips(): void
    {
        $this->fakeVerify();
        $user = $this->employeeWithFace();
        $uuidA = fake()->uuid();
        $uuidB = fake()->uuid();

        // Dua item beda client_uuid, tapi hari yang sama -> yang pertama dibuat,
        // yang kedua dilewati (satu absensi per hari).
        $response = $this->actingAs($user, 'sanctum')->postJson('/api/attendance/sync', [
            'anchor' => $this->anchor(),
            'boot_count' => 1,
            'items' => [$this->item($uuidA, 2000), $this->item($uuidB, 3000)],
        ])->assertOk();

        $this->assertSame('created', $response->json('data.0.status'));
        $this->assertSame('skipped_existing', $response->json('data.1.status'));
        $this->assertDatabaseCount('attendances', 1);
    }

    public function test_sync_from_backup_device_is_pending(): void
    {
        $this->fakeVerify();
        $user = $this->employeeWithFace('backup-uid', 'backup');
        $uuid = fake()->uuid();

        $this->actingAs($user, 'sanctum')->postJson('/api/attendance/sync', [
            'anchor' => $this->anchor(),
            'boot_count' => 1,
            'items' => [$this->item($uuid, 2000, 'backup-uid')],
        ])->assertOk();

        $attendance = Attendance::where('client_uuid', $uuid)->firstOrFail();
        $this->assertTrue($attendance->is_backup_device);
        $this->assertSame('pending', $attendance->approval_status);
    }

    public function test_sync_outside_area_flags_review(): void
    {
        $this->fakeVerify();
        $user = $this->employeeWithFace();
        $uuid = fake()->uuid();
        $item = $this->item($uuid, 2000);
        $item['lat'] = 0.0;
        $item['lng'] = 0.0;

        $this->actingAs($user, 'sanctum')->postJson('/api/attendance/sync', [
            'anchor' => $this->anchor(),
            'boot_count' => 1,
            'items' => [$item],
        ])->assertOk()->assertJsonPath('data.0.review_flag', true);
    }
}
