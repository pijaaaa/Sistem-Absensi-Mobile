<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\WithHeadings;

class AttendanceRecapExport implements FromArray, WithHeadings
{
    /**
     * @param  array<int, array<int, mixed>>  $rows
     */
    public function __construct(private array $rows) {}

    public function array(): array
    {
        return $this->rows;
    }

    public function headings(): array
    {
        return [
            'Nama', 'NIP', 'Department', 'Lokasi', 'Hadir', 'Telat',
            'Total Menit Telat', 'Alfa', 'Cuti', 'Sakit', 'Izin', 'Dinas',
        ];
    }
}
