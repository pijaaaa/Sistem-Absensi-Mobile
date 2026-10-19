<?php

namespace App\Console\Commands;

use App\Models\Department;
use App\Models\Employee;
use App\Models\User;
use App\Models\WorkLocation;
use App\Models\WorkSchedule;
use App\Services\ScheduleService;
use Carbon\Carbon;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

#[Signature('app:seed-dummy {--employees=200} {--days=60}')]
#[Description('Buat data dummy realistis: karyawan, manager, lokasi, dan riwayat absensi beberapa bulan.')]
class SeedDummyData extends Command
{
    public function handle(ScheduleService $schedule): int
    {
        $count = (int) $this->option('employees');
        $days = (int) $this->option('days');

        $point = WorkLocation::firstOrCreate(['name' => 'Kantor Pusat (Dummy)'], [
            'mode' => 'point', 'lat' => -6.2088, 'lng' => 106.8456, 'radius_m' => 150,
        ]);
        $polygon = WorkLocation::firstOrCreate(['name' => 'Kantor Cabang (Dummy)'], [
            'mode' => 'polygon', 'polygon_json' => [[-6.2100, 106.8400], [-6.2050, 106.8500], [-6.2130, 106.8520]],
        ]);

        $deptNames = ['Teknologi', 'Keuangan', 'Operasional', 'SDM'];
        $departments = collect($deptNames)->map(fn ($name) => Department::firstOrCreate(['name' => $name]));

        $this->info('Membuat karyawan...');
        $this->makeStaff($departments, $point, $polygon, $count);

        $this->info('Membuat riwayat absensi...');
        $this->makeHistory($days, $schedule);

        $this->info('Selesai. Karyawan dibuat: '.$count.', riwayat: '.$days.' hari (hari kerja saja).');

        return self::SUCCESS;
    }

    private function makeStaff($departments, WorkLocation $point, WorkLocation $polygon, int $count): void
    {
        $locations = [$point, $polygon];
        $i = 0;

        foreach ($departments as $idx => $department) {
            // 1 manager per department — reuse bila sudah ada manager aktif.
            $hasManager = Employee::where('department_id', $department->id)
                ->where('is_active', true)
                ->whereHas('user', fn ($q) => $q->where('role', 'manager_department')->where('is_active', true))
                ->exists();

            if (! $hasManager) {
                $managerEmail = 'manager'.$idx.'@dummy.test';
                $manager = User::firstOrCreate(['email' => $managerEmail], [
                    'name' => 'Manager '.$department->name,
                    'password' => 'password',
                    'role' => 'manager_department',
                    'is_active' => true,
                ]);

                Employee::firstOrCreate(['nip' => sprintf('MGR-%03d', $idx)], [
                    'user_id' => $manager->id,
                    'name' => $manager->name,
                    'department_id' => $department->id,
                    'work_location_id' => $locations[$idx % 2]->id,
                    'is_active' => true,
                ]);
            }
        }

        $perDept = (int) floor($count / $departments->count());

        foreach ($departments as $idx => $department) {
            for ($k = 0; $k < $perDept; $k++) {
                $i++;
                $email = 'karyawan'.$i.'@dummy.test';
                $user = User::firstOrCreate(['email' => $email], [
                    'name' => 'Karyawan '.$i,
                    'password' => 'password',
                    'role' => 'karyawan',
                    'is_active' => true,
                ]);

                Employee::firstOrCreate(['nip' => sprintf('KRW-%04d', $i)], [
                    'user_id' => $user->id,
                    'name' => $user->name,
                    'department_id' => $department->id,
                    'work_location_id' => $locations[$i % 2]->id,
                    'is_active' => true,
                ]);
            }
        }
    }

    private function makeHistory(int $days, ScheduleService $schedule): void
    {
        $tz = WorkSchedule::current()?->timezone ?? config('app.timezone');
        $today = Carbon::now($tz);
        $employeeIds = Employee::where('is_active', true)->pluck('id');
        $rows = [];

        for ($offset = $days; $offset >= 1; $offset--) {
            $day = $today->copy()->subDays($offset);

            if (! $schedule->isWorkday($day)) {
                continue;
            }

            foreach ($employeeIds as $employeeId) {
                $roll = rand(1, 100);
                $date = $day->toDateString();

                if ($roll <= 8) {
                    $rows[] = [
                        'employee_id' => $employeeId, 'date' => $date,
                        'check_in_at' => null, 'check_out_at' => null,
                        'in_lat' => null, 'in_lng' => null, 'out_lat' => null, 'out_lng' => null,
                        'late_minutes' => 0, 'late_level' => null, 'is_absent' => true,
                        'created_at' => now(), 'updated_at' => now(),
                    ];
                } elseif ($roll <= 92) {
                    $late = rand(0, 30);
                    $in = Carbon::parse($date.' 08:00', $tz)->addMinutes($late);
                    $out = Carbon::parse($date.' 17:00', $tz);
                    $rows[] = [
                        'employee_id' => $employeeId, 'date' => $date,
                        'check_in_at' => $in, 'check_out_at' => $out,
                        'in_lat' => -6.2088, 'in_lng' => 106.8456, 'out_lat' => -6.2088, 'out_lng' => 106.8456,
                        'late_minutes' => $late, 'late_level' => match (true) {
                            $late <= 5 => 'green', $late <= 15 => 'yellow', default => 'red',
                        },
                        'is_absent' => false,
                        'created_at' => now(), 'updated_at' => now(),
                    ];
                }
                // roll 93-100: belum absen (biarkan, nanti ditandai alfa oleh job).
            }
        }

        foreach (array_chunk($rows, 1000) as $chunk) {
            DB::table('attendances')->insert($chunk);
        }
    }
}
