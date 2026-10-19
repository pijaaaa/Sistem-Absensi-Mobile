<?php

namespace Tests\Feature\Web;

use App\Models\Attendance;
use App\Models\Department;
use App\Models\FaceCapture;
use App\Models\WorkLocation;
use Carbon\Carbon;
use Database\Seeders\ModulePermissionSeeder;
use Database\Seeders\RolePermissionSeeder;
use Database\Seeders\ScheduleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class ReviewTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow(Carbon::create(2026, 10, 19, 10, 0, 0, 'Asia/Jakarta'));
        $this->seed([ModulePermissionSeeder::class, RolePermissionSeeder::class, ScheduleSeeder::class]);
        Storage::fake('local');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function flaggedAttendance(): Attendance
    {
        $department = Department::create(['name' => 'Teknologi']);
        $location = WorkLocation::create(['name' => 'Kantor', 'mode' => 'off']);
        $karyawan = $this->makeEmployeeUser('karyawan', $department);
        $karyawan->employee->update(['work_location_id' => $location->id]);

        return Attendance::create([
            'employee_id' => $karyawan->employee->id,
            'date' => now()->toDateString(),
            'check_in_at' => now(),
            'review_flag' => true,
            'time_trust' => 'suspect',
            'face_score_local' => 0.9,
            'face_score_server' => 0.3,
        ]);
    }

    public function test_review_page_lists_flagged(): void
    {
        $attendance = $this->flaggedAttendance();
        $this->actingAs($this->makeUser('superadmin'));

        $this->get('/review')->assertOk()->assertSee($attendance->employee->name);
    }

    public function test_mark_valid_records_audit(): void
    {
        $attendance = $this->flaggedAttendance();
        $this->actingAs($this->makeUser('superadmin'));

        $this->post("/review/{$attendance->id}", ['review_status' => 'valid', 'review_note' => 'ok'])
            ->assertRedirect();

        $attendance->refresh();
        $this->assertSame('valid', $attendance->review_status);
        $this->assertSame('ok', $attendance->review_note);
        $this->assertDatabaseHas('audit_logs', ['action' => 'review.marked']);
    }

    public function test_photo_served_when_not_expired_and_404_when_expired(): void
    {
        $attendance = $this->flaggedAttendance();
        Storage::disk('local')->put('face_captures/in.jpg', 'img');

        $capture = FaceCapture::create([
            'attendance_id' => $attendance->id, 'type' => 'in',
            'path' => 'face_captures/in.jpg', 'expires_at' => now()->addDays(30),
        ]);

        $this->actingAs($this->makeUser('superadmin'));
        $this->get("/review/photo/{$capture->id}")->assertOk();

        $capture->update(['expires_at' => now()->subDay()]);
        $this->get("/review/photo/{$capture->id}")->assertNotFound();
    }
}
