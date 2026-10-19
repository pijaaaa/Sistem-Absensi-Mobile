<?php

namespace App\Services;

use Carbon\CarbonInterface;

/**
 * Pulang awal = selisih menit sebelum jam pulang jadwal.
 */
class EarlyLeaveService
{
    public function minutes(CarbonInterface $checkout, CarbonInterface $scheduledEnd): int
    {
        if ($checkout->greaterThanOrEqualTo($scheduledEnd)) {
            return 0;
        }

        return (int) floor(($scheduledEnd->timestamp - $checkout->timestamp) / 60);
    }
}
