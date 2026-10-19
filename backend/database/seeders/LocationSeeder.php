<?php

namespace Database\Seeders;

use App\Models\Department;
use App\Models\WorkLocation;
use Illuminate\Database\Seeder;

class LocationSeeder extends Seeder
{
    public function run(): void
    {
        WorkLocation::firstOrCreate(['name' => 'Kantor Pusat (Point)'], [
            'mode' => 'point',
            'lat' => -6.2088,
            'lng' => 106.8456,
            'radius_m' => 150,
            'polygon_json' => null,
        ]);

        WorkLocation::firstOrCreate(['name' => 'Kantor Cabang (Polygon)'], [
            'mode' => 'polygon',
            'lat' => null,
            'lng' => null,
            'radius_m' => null,
            'polygon_json' => [
                [-6.2100, 106.8400],
                [-6.2050, 106.8500],
                [-6.2130, 106.8520],
            ],
        ]);

        Department::firstOrCreate(['name' => 'Teknologi']);
        Department::firstOrCreate(['name' => 'Keuangan']);
    }
}
