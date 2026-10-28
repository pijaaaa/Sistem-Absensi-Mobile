<?php

namespace Tests\Feature;

use App\Models\Department;
use App\Models\Employee;
use App\Models\LeaveBalance;
use App\Models\LeaveRequest;
use App\Models\NotificationPreference;
use App\Models\User;
use App\Models\WorkLocation;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PushNotificationPhase2Test extends TestCase
{
    use RefreshDatabase;

    private function createDeptAndLocation(): array
    {
        $dept = Department::create(['name' => 'IT']);
        $loc = WorkLocation::create(['name' => 'Kantor Pusat', 'lat' => 0, 'lng' => 0, 'radius_m' => 100]);
        return [$dept, $loc];
    }

    public function test_notification_preferences_blocking(): void
    {
        [$dept, $loc] = $this->createDeptAndLocation();

        $user = User::create([
            'name' => 'Fikri',
            'email' => 'fikri@test.com',
            'password' => bcrypt('password'),
            'role' => 'karyawan',
            'is_active' => true,
        ]);
        Employee::create([
            'user_id' => $user->id,
            'nip' => '12345',
            'name' => 'Fikri',
            'department_id' => $dept->id,
            'work_location_id' => $loc->id,
            'is_active' => true,
        ]);

        NotificationPreference::create([
            'user_id' => $user->id,
            'type' => 'reminder_checkin',
            'enabled' => false,
        ]);

        $notifier = app(NotificationService::class);

        $res1 = $notifier->send($user, 'Test', 'Body', ['type' => 'reminder_checkin'], 'dup1');
        $this->assertNull($res1);

        $res2 = $notifier->send($user, 'Test', 'Body', ['type' => 'leave_decision'], 'dup2');
        $this->assertNotNull($res2);
    }

    public function test_leave_expiry_command(): void
    {
        [$dept, $loc] = $this->createDeptAndLocation();

        $user = User::create([
            'name' => 'Fikri',
            'email' => 'fikri2@test.com',
            'password' => bcrypt('password'),
            'role' => 'karyawan',
            'is_active' => true,
        ]);
        $employee = Employee::create([
            'user_id' => $user->id,
            'nip' => '12346',
            'name' => 'Fikri',
            'department_id' => $dept->id,
            'work_location_id' => $loc->id,
            'is_active' => true,
        ]);

        LeaveBalance::create([
            'employee_id' => $employee->id,
            'year' => now()->year,
            'quota' => 12,
            'used' => 0,
        ]);

        \App\Models\Setting::put('notif_leave_expiry_dates', now()->format('m-d'));
        \App\Models\Setting::put('notif_leave_expiry_threshold', '3');

        $this->artisan('notifications:leave-expiry')
            ->expectsOutputToContain('Notifikasi sisa cuti dikirim: 1')
            ->assertSuccessful();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $user->id,
        ]);
    }

    public function test_pending_approval_command(): void
    {
        [$dept, $loc] = $this->createDeptAndLocation();

        $managerUser = User::create([
            'name' => 'Manager',
            'email' => 'mgr@test.com',
            'password' => bcrypt('password'),
            'role' => 'manager_department',
            'is_active' => true,
        ]);
        Employee::create([
            'user_id' => $managerUser->id,
            'nip' => 'MGR1',
            'name' => 'Manager',
            'department_id' => $dept->id,
            'work_location_id' => $loc->id,
            'is_active' => true,
        ]);

        $staffUser = User::create([
            'name' => 'Staff',
            'email' => 'staff@test.com',
            'password' => bcrypt('password'),
            'role' => 'karyawan',
            'is_active' => true,
        ]);
        $staffEmp = Employee::create([
            'user_id' => $staffUser->id,
            'nip' => 'STF1',
            'name' => 'Staff',
            'department_id' => $dept->id,
            'work_location_id' => $loc->id,
            'is_active' => true,
        ]);

        $leave = LeaveRequest::create([
            'employee_id' => $staffEmp->id,
            'type' => 'cuti',
            'start_date' => now()->addDays(2),
            'end_date' => now()->addDays(3),
            'status' => 'pending',
        ]);
        $leave->created_at = now()->subHours(25);
        $leave->save();

        $this->artisan('notifications:pending-approval')
            ->expectsOutputToContain('Notifikasi pending approval dikirim: 1')
            ->assertSuccessful();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $managerUser->id,
        ]);
    }
}
