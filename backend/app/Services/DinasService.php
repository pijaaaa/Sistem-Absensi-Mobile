<?php

namespace App\Services;

use Carbon\CarbonInterface;
use Illuminate\Support\Collection;

/**
 * Logika dinas (pure). Pemanggil (B6/B8) mengisi koleksi rentang tanggal dinas
 * yang sudah disetujui; service tidak bergantung tabel leave_requests.
 */
class DinasService
{
    /**
     * @param  Collection<int, array{start: CarbonInterface, end: CarbonInterface}>  $approvedRanges
     */
    public function coversDate(CarbonInterface $date, Collection $approvedRanges): bool
    {
        foreach ($approvedRanges as $range) {
            if ($date->betweenIncluded($range['start'], $range['end'])) {
                return true;
            }
        }

        return false;
    }
}
