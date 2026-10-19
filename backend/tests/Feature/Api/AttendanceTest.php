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
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class AttendanceTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    private Department $department;

    private WorkLocation $location;

    protected function setUp(): void
    {
        parent::setUp();
        // Senin 08:03 (Asia/Jakarta) — deterministik untuk telat & hari kerja.
        Carbon::setTestNow(Carbon::create(2026, 10, 19, 8, 3, 0, 'Asia/Jakarta'));

        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, ScheduleSeeder::class]);

        $this->department = Department::create(['name' => 'Teknologi']);
        $this->location = WorkLocation::create([
            'name' => 'Kantor',
            'mode' => 'point',
            'lat' => -6.2,
            'lng' => 106.8,
            'radius_m' => 200,
        ]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function employeeWithFace(): User
    {
        $user = $this->makeEmployeeUser('karyawan', $this->department);
        $user->employee->update(['work_location_id' => $this->location->id]);

        FaceTemplate::create([
            'employee_id' => $user->employee->id,
            'embedding' => array_fill(0, 128, 0.1),
            'model_version' => 'sface-2021dec+yunet-2023mar',
        ]);

        return $user->fresh('employee');
    }

    private function fakeVerifyMatch(bool $match = true): void
    {
        Http::fake([
            '*/verify' => Http::response([
                'model_version' => 'sface-2021dec+yunet-2023mar',
                'score' => $match ? 0.9 : 0.1,
                'threshold' => 0.363,
                'match' => $match,
            ], 200),
        ]);
    }

    private function checkIn(User $user, string $uid = 'dev-A', float $lat = -6.2, float $lng = 106.8)
    {
        return $this->actingAs($user, 'sanctum')->post('/api/attendance/check-in', [
            'lat' => $lat,
            'lng' => $lng,
            'device_uid' => $uid,
            'photo' => UploadedFile::fake()->image('face.jpg'),
            'face_score_local' => 0.95,
        ]);
    }

    public function test_check_in_non_workday_rejected(): void
    {
        $this->fakeVerifyMatch();
        $user = $this->employeeWithFace();
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'dev-A', 'type' => 'primary', 'status' => 'active']);

        Carbon::setTestNow(Carbon::create(2026, 10, 24, 8, 0, 0, 'Asia/Jakarta')); // Sabtu

        $this->checkIn($user)->assertStatus(422);
        $this->assertDatabaseCount('attendances', 0);
    }

    public function test_login_first_device_becomes_primary(): void
    {
        $user = $this->employeeWithFace();

        $this->postJson('/api/auth/login', [
            'login' => $user->email,
            'password' => 'password',
            'device_uid' => 'dev-A',
            'device_name' => 'HP Budi',
        ])->assertOk()->assertJsonPath('data.device.type', 'primary');

        $this->assertDatabaseHas('devices', ['employee_id' => $user->employee->id, 'device_uid' => 'dev-A', 'type' => 'primary']);
    }

    public function test_check_in_success_within_geofence(): void
    {
        $this->fakeVerifyMatch();
        $user = $this->employeeWithFace();
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'dev-A', 'type' => 'primary', 'status' => 'active', 'registered_at' => now()]);

        $this->checkIn($user)->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['status', 'late_minutes', 'late_level', 'color', 'approval_status']]);

        $this->assertDatabaseCount('attendances', 1);
        $this->assertDatabaseHas('face_captures', ['type' => 'in']);
    }

    public function test_check_in_outside_geofence_rejected(): void
    {
        $this->fakeVerifyMatch();
        $user = $this->employeeWithFace();
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'dev-A', 'type' => 'primary', 'status' => 'active']);

        $this->checkIn($user, 'dev-A', 0.0, 0.0)->assertStatus(422);
        $this->assertDatabaseCount('attendances', 0);
    }

    public function test_duplicate_check_in_rejected(): void
    {
        $this->fakeVerifyMatch();
        $user = $this->employeeWithFace();
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'dev-A', 'type' => 'primary', 'status' => 'active']);

        $this->checkIn($user)->assertOk();
        $this->checkIn($user)->assertStatus(422);
        $this->assertDatabaseCount('attendances', 1);
    }

    public function test_check_in_without_face_template_rejected(): void
    {
        Http::fake();
        $user = $this->employeeWithFace();
        $user->employee->faceTemplates()->delete();
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'dev-A', 'type' => 'primary', 'status' => 'active']);

        $this->checkIn($user)->assertStatus(422)->assertJsonPath('message', 'Wajah belum terdaftar.');
    }

    public function test_face_mismatch_rejected(): void
    {
        $this->fakeVerifyMatch(false);
        $user = $this->employeeWithFace();
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'dev-A', 'type' => 'primary', 'status' => 'active']);

        $this->checkIn($user)->assertStatus(422);
        $this->assertDatabaseCount('attendances', 0);
    }

    public function test_unregistered_device_rejected(): void
    {
        $this->fakeVerifyMatch();
        $user = $this->employeeWithFace();
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'primary-uid', 'type' => 'primary', 'status' => 'active']);

        $this->checkIn($user, 'unknown-uid')->assertStatus(422);
    }

    public function test_backup_device_check_in_is_pending(): void
    {
        $this->fakeVerifyMatch();
        $user = $this->employeeWithFace();
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'primary-uid', 'type' => 'primary', 'status' => 'active']);
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'backup-uid', 'type' => 'backup', 'status' => 'active']);

        $this->checkIn($user, 'backup-uid')->assertOk()->assertJsonPath('data.approval_status', 'pending');

        $attendance = Attendance::first();
        $this->assertTrue($attendance->is_backup_device);
        $this->assertSame('pending', $attendance->approval_status);
    }

    public function test_register_second_backup_rejected(): void
    {
        $user = $this->employeeWithFace();
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'p', 'type' => 'primary', 'status' => 'active']);
        Device::create(['employee_id' => $user->employee->id, 'device_uid' => 'b1', 'type' => 'backup', 'status' => 'active']);

        $this->actingAs($user, 'sanctum')->postJson('/api/devices/register-backup', ['device_uid' => 'b2'])
            ->assertStatus(422);
    }
}
