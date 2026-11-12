<?php

namespace Database\Seeders;

use App\Models\Attendance;
use App\Models\Device;
use App\Models\Employee;
use App\Models\Holiday;
use App\Models\LeaveRequest;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $employees = Employee::query()->orderBy('id')->take(3)->get();
        if ($employees->isEmpty()) {
            return;
        }

        Holiday::firstOrCreate(['date' => '2026-12-25'], ['name' => 'Hari Raya Natal']);
        Holiday::firstOrCreate(['date' => '2027-01-01'], ['name' => 'Tahun Baru']);

        foreach ($employees as $index => $employee) {
            Device::firstOrCreate(
                ['employee_id' => $employee->id, 'device_uid' => 'DEMO-DEVICE-'.($index + 1)],
                ['name' => 'Ponsel '.($index + 1), 'type' => $index === 0 ? 'primary' : 'backup', 'status' => 'active', 'registered_at' => now()]
            );
        }

        LeaveRequest::firstOrCreate(
            ['employee_id' => $employees[0]->id, 'start_date' => '2026-12-07'],
            ['type' => 'izin', 'end_date' => '2026-12-08', 'reason' => 'Keperluan keluarga', 'status' => 'pending']
        );
        LeaveRequest::firstOrCreate(
            ['employee_id' => $employees[1]->id, 'start_date' => '2026-12-10'],
            ['type' => 'sakit', 'end_date' => '2026-12-10', 'reason' => 'Pemeriksaan kesehatan', 'status' => 'pending']
        );

        foreach ($employees as $index => $employee) {
            Attendance::firstOrCreate(
                ['employee_id' => $employee->id, 'date' => Carbon::today()->subDays($index + 1)->toDateString()],
                [
                    'check_in_at' => now()->subDays($index + 1)->setTime(8, 15),
                    'late_minutes' => 15,
                    'late_level' => 'yellow',
                    'approval_status' => $index === 0 ? 'pending' : 'none',
                    'review_flag' => $index === 1,
                    'review_note' => $index === 1 ? 'Perlu verifikasi data absensi' : null,
                    'location_id' => $employee->work_location_id,
                ]
            );
        }
    }
}
