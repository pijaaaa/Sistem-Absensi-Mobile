<?php

namespace Database\Seeders;

use App\Models\Department;
use App\Models\Employee;
use App\Models\User;
use App\Models\WorkLocation;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $point = WorkLocation::where('name', 'Kantor Pusat (Point)')->first();
        $polygon = WorkLocation::where('name', 'Kantor Cabang (Polygon)')->first();

        User::firstOrCreate(['email' => 'admin@example.com'], [
            'name' => 'Super Admin',
            'password' => bcrypt('password'),
            'role' => 'superadmin',
            'is_active' => true,
        ]);

        $this->makeManager('manager.teknologi@example.com', 'Manager Teknologi', 'MGR-TEK-001', 'Teknologi', $point);
        $this->makeManager('manager.keuangan@example.com', 'Manager Keuangan', 'MGR-KEU-001', 'Keuangan', $polygon);

        $this->makeKaryawan('budi@example.com', 'Budi Santoso', 'KRW-TEK-001', 'Teknologi', $point);
        $this->makeKaryawan('siti@example.com', 'Siti Rahayu', 'KRW-TEK-002', 'Teknologi', $polygon);
        $this->makeKaryawan('andi@example.com', 'Andi Wijaya', 'KRW-KEU-001', 'Keuangan', $polygon);
    }

    private function makeManager(string $email, string $name, string $nip, string $dept, WorkLocation $loc): void
    {
        $user = User::firstOrCreate(['email' => $email], [
            'name' => $name,
            'password' => bcrypt('password'),
            'role' => 'manager_department',
            'is_active' => true,
        ]);

        Employee::firstOrCreate(['nip' => $nip], [
            'user_id' => $user->id,
            'name' => $name,
            'department_id' => Department::where('name', $dept)->first()->id,
            'work_location_id' => $loc->id,
            'is_active' => true,
        ]);
    }

    private function makeKaryawan(string $email, string $name, string $nip, string $dept, WorkLocation $loc): void
    {
        $user = User::firstOrCreate(['email' => $email], [
            'name' => $name,
            'password' => bcrypt('password'),
            'role' => 'karyawan',
            'is_active' => true,
        ]);

        Employee::firstOrCreate(['nip' => $nip], [
            'user_id' => $user->id,
            'name' => $name,
            'department_id' => Department::where('name', $dept)->first()->id,
            'work_location_id' => $loc->id,
            'is_active' => true,
        ]);
    }
}
