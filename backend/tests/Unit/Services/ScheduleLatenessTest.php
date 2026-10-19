<?php

namespace Tests\Unit\Services;

use App\Models\Holiday;
use App\Models\LatenessRule;
use App\Models\WorkSchedule;
use App\Services\EarlyLeaveService;
use App\Services\LatenessService;
use App\Services\ScheduleService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ScheduleLatenessTest extends TestCase
{
    use RefreshDatabase;

    private Carbon $mon;

    private Carbon $sat;

    private Carbon $sun;

    protected function setUp(): void
    {
        parent::setUp();
        WorkSchedule::updateOrCreate(['id' => 1], [
            'work_days' => [1, 2, 3, 4, 5],
            'start_time' => '08:00',
            'end_time' => '17:00',
            'timezone' => 'Asia/Jakarta',
        ]);

        // Senin=1, Sabtu=6, Minggu=0 (Carbon default en_US).
        $this->mon = Carbon::create(2026, 10, 19, 9, 0, 0, 'Asia/Jakarta'); // Senin
        $this->sat = Carbon::create(2026, 10, 24, 9, 0, 0, 'Asia/Jakarta'); // Sabtu
        $this->sun = Carbon::create(2026, 10, 25, 9, 0, 0, 'Asia/Jakarta'); // Minggu
    }

    public function test_workday_monday_is_workday(): void
    {
        $this->assertTrue((new ScheduleService)->isWorkday($this->mon));
    }

    public function test_weekend_is_not_workday(): void
    {
        $svc = new ScheduleService;
        $this->assertFalse($svc->isWorkday($this->sat));
        $this->assertFalse($svc->isWorkday($this->sun));
    }

    public function test_holiday_is_not_workday(): void
    {
        Holiday::create(['date' => $this->mon->toDateString(), 'name' => 'Hari Libur']);

        $this->assertFalse((new ScheduleService)->isWorkday($this->mon));
    }

    public function test_lateness_ranges_and_boundary(): void
    {
        $start = Carbon::create(2026, 10, 19, 8, 0, 0, 'Asia/Jakarta');
        $rules = collect([
            new LatenessRule(['from_minute' => 0, 'to_minute' => 5, 'label' => 'Toleransi', 'color' => 'green', 'is_counted_late' => false]),
            new LatenessRule(['from_minute' => 6, 'to_minute' => 15, 'label' => 'Kuning', 'color' => 'yellow', 'is_counted_late' => true]),
            new LatenessRule(['from_minute' => 16, 'to_minute' => null, 'label' => 'Merah', 'color' => 'red', 'is_counted_late' => true]),
        ]);

        $svc = new LatenessService;

        // tepat waktu / lebih cepat.
        $r = $svc->evaluate(Carbon::create(2026, 10, 19, 8, 0, 0, 'Asia/Jakarta'), $start, $rules);
        $this->assertSame(0, $r->minutes);
        $this->assertFalse($r->countedLate);

        // 4 menit -> toleransi, tidak dihitung.
        $r = $svc->evaluate(Carbon::create(2026, 10, 19, 8, 4, 0, 'Asia/Jakarta'), $start, $rules);
        $this->assertSame(4, $r->minutes);
        $this->assertSame('Toleransi', $r->label);
        $this->assertFalse($r->countedLate);

        // tepat 5 menit -> masih toleransi (inklusif).
        $r = $svc->evaluate(Carbon::create(2026, 10, 19, 8, 5, 0, 'Asia/Jakarta'), $start, $rules);
        $this->assertSame('Toleransi', $r->label);

        // 10 menit -> kuning.
        $r = $svc->evaluate(Carbon::create(2026, 10, 19, 8, 10, 0, 'Asia/Jakarta'), $start, $rules);
        $this->assertSame('Kuning', $r->label);
        $this->assertTrue($r->countedLate);

        // 20 menit -> merah.
        $r = $svc->evaluate(Carbon::create(2026, 10, 19, 8, 20, 0, 'Asia/Jakarta'), $start, $rules);
        $this->assertSame('Merah', $r->label);
        $this->assertTrue($r->countedLate);
    }

    public function test_early_leave_minutes(): void
    {
        $end = Carbon::create(2026, 10, 19, 17, 0, 0, 'Asia/Jakarta');
        $svc = new EarlyLeaveService;

        $this->assertSame(30, $svc->minutes(
            Carbon::create(2026, 10, 19, 16, 30, 0, 'Asia/Jakarta'), $end
        ));

        $this->assertSame(0, $svc->minutes(
            Carbon::create(2026, 10, 19, 17, 0, 0, 'Asia/Jakarta'), $end
        ));

        $this->assertSame(0, $svc->minutes(
            Carbon::create(2026, 10, 19, 17, 30, 0, 'Asia/Jakarta'), $end
        ));
    }
}
