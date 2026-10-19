<?php

namespace Tests\Feature\Commands;

use App\Models\Attendance;
use App\Models\Department;
use App\Models\FaceCapture;
use App\Models\FaceTemplate;
use App\Models\LeaveRequest;
use Carbon\Carbon;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Database\Seeders\ScheduleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class AttendanceJobsTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow(Carbon::create(2026, 10, 19, 8, 0, 0, 'Asia/Jakarta')); // Senin
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, ScheduleSeeder::class]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_purge_only_removes_expired_captures(): void
    {
        Storage::fake('local');

        $user = $this->makeEmployeeUser('karyawan', Department::create(['name' => 'A']));
        $attendance = Attendance::create([
            'employee_id' => $user->employee->id,
            'date' => now()->toDateString(),
            'check_in_at' => now(),
        ]);

        Storage::disk('local')->put('face_captures/expired.jpg', 'old');
        Storage::disk('local')->put('face_captures/valid.jpg', 'new');

        $expired = FaceCapture::create([
            'attendance_id' => $attendance->id, 'type' => 'in',
            'path' => 'face_captures/expired.jpg', 'expires_at' => now()->subDay(),
        ]);
        $valid = FaceCapture::create([
            'attendance_id' => $attendance->id, 'type' => 'in',
            'path' => 'face_captures/valid.jpg', 'expires_at' => now()->addDays(30),
        ]);

        $this->artisan('app:purge-expired-face-captures')->assertSuccessful();

        $this->assertDatabaseMissing('face_captures', ['id' => $expired->id]);
        $this->assertDatabaseHas('face_captures', ['id' => $valid->id]);
        Storage::disk('local')->assertMissing('face_captures/expired.jpg');
        Storage::disk('local')->assertExists('face_captures/valid.jpg');

        // Template wajah tidak ikut terhapus.
        FaceTemplate::create([
            'employee_id' => $user->employee->id,
            'embedding' => array_fill(0, 128, 0.1),
            'model_version' => 'x',
        ]);
        $this->assertDatabaseCount('face_templates', 1);
    }

    public function test_mark_absentees_creates_alfa_for_missing(): void
    {
        $department = Department::create(['name' => 'A']);
        $karyawanTanpaAbsen = $this->makeEmployeeUser('karyawan', $department);

        // Ada yang sudah absen.
        $sudahAbsen = $this->makeEmployeeUser('karyawan', $department);
        Attendance::create([
            'employee_id' => $sudahAbsen->employee->id,
            'date' => now()->toDateString(), 'check_in_at' => now(),
        ]);

        // Sedang cuti disetujui.
        $dinas = $this->makeEmployeeUser('karyawan', $department);
        LeaveRequest::create([
            'employee_id' => $dinas->employee->id,
            'type' => 'cuti', 'start_date' => now()->toDateString(), 'end_date' => now()->toDateString(),
            'status' => 'approved',
        ]);

        $this->artisan('app:mark-absentees', ['--date' => '2026-10-19'])->assertSuccessful();

        $this->assertDatabaseHas('attendances', [
            'employee_id' => $karyawanTanpaAbsen->employee->id,
            'is_absent' => true,
        ]);

        $absents = Attendance::where('is_absent', true)->get();
        $absentIds = $absents->pluck('employee_id');

        $this->assertTrue($absentIds->contains($karyawanTanpaAbsen->employee->id));
        $this->assertFalse($absentIds->contains($sudahAbsen->employee->id));
        $this->assertFalse($absentIds->contains($dinas->employee->id));
    }

    public function test_mark_absentees_skips_non_workday(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 10, 19, 8, 0, 0, 'Asia/Jakarta'));
        $department = Department::create(['name' => 'A']);
        $karyawan = $this->makeEmployeeUser('karyawan', $department);

        $this->artisan('app:mark-absentees', ['--date' => '2026-10-24'])->assertSuccessful(); // Sabtu

        $this->assertDatabaseMissing('attendances', ['employee_id' => $karyawan->employee->id]);
    }
}
