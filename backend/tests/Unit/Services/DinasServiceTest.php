<?php

namespace Tests\Unit\Services;

use App\Services\DinasService;
use Carbon\Carbon;
use Tests\TestCase;

class DinasServiceTest extends TestCase
{
    public function test_covers_date_within_range_true_and_outside_false(): void
    {
        $svc = new DinasService;

        $ranges = collect([
            ['start' => Carbon::create(2026, 10, 19, 0, 0, 0, 'Asia/Jakarta'),
                'end' => Carbon::create(2026, 10, 21, 0, 0, 0, 'Asia/Jakarta')],
        ]);

        $this->assertTrue($svc->coversDate(
            Carbon::create(2026, 10, 19, 12, 0, 0, 'Asia/Jakarta'), $ranges
        ));
        $this->assertTrue($svc->coversDate(
            Carbon::create(2026, 10, 21, 0, 0, 0, 'Asia/Jakarta'), $ranges
        ));

        $this->assertFalse($svc->coversDate(
            Carbon::create(2026, 10, 25, 12, 0, 0, 'Asia/Jakarta'), $ranges
        ));
    }

    public function test_no_approved_ranges_means_not_dinas(): void
    {
        $this->assertFalse((new DinasService)->coversDate(
            Carbon::create(2026, 10, 19, 12, 0, 0, 'Asia/Jakarta'),
            collect()
        ));
    }
}
