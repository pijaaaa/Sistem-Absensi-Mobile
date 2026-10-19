<?php

namespace App\Services;

use App\Models\Holiday;
use App\Models\WorkSchedule;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\Cache;

class ScheduleService
{
    public function isWorkday(CarbonInterface $date): bool
    {
        $schedule = WorkSchedule::current();

        if (! $schedule) {
            return false;
        }

        // Carbon dayOfWeek: 0=minggu ... 6=sabtu.
        if (! in_array($date->dayOfWeek, $schedule->work_days, true)) {
            return false;
        }

        return ! $this->isHoliday($date);
    }

    public function isHoliday(CarbonInterface $date): bool
    {
        $dates = Cache::rememberForever('holidays:all', fn () => Holiday::query()
            ->pluck('date')
            ->map(fn ($d) => $d->toDateString())
            ->all());

        return in_array($date->toDateString(), $dates, true);
    }

    public function flushCache(): void
    {
        Cache::forget('holidays:all');
    }
}
