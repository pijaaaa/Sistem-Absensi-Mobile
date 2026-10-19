<?php

namespace Database\Seeders;

use App\Models\LatenessRule;
use App\Models\WorkSchedule;
use Illuminate\Database\Seeder;

class ScheduleSeeder extends Seeder
{
    public function run(): void
    {
        WorkSchedule::updateOrCreate(['id' => 1], [
            'work_days' => [1, 2, 3, 4, 5],
            'start_time' => '08:00',
            'end_time' => '17:00',
            'timezone' => 'Asia/Jakarta',
        ]);

        LatenessRule::query()->delete();

        LatenessRule::insert([
            ['label' => 'Toleransi', 'from_minute' => 0, 'to_minute' => 5, 'color' => 'green', 'is_counted_late' => false, 'created_at' => now(), 'updated_at' => now()],
            ['label' => 'Kuning', 'from_minute' => 6, 'to_minute' => 15, 'color' => 'yellow', 'is_counted_late' => true, 'created_at' => now(), 'updated_at' => now()],
            ['label' => 'Merah', 'from_minute' => 16, 'to_minute' => null, 'color' => 'red', 'is_counted_late' => true, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}
