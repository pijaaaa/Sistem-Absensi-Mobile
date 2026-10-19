<?php

namespace App\Services;

use App\Models\LatenessRule;
use App\Services\Dto\LatenessResult;
use Carbon\CarbonInterface;
use Illuminate\Support\Collection;

class LatenessService
{
    /**
     * @param  Collection<int, LatenessRule>  $rules
     */
    public function evaluate(CarbonInterface $actual, CarbonInterface $scheduledStart, Collection $rules): LatenessResult
    {
        if ($actual->lessThanOrEqualTo($scheduledStart)) {
            return new LatenessResult(0, null, null, false);
        }

        $lateMinutes = (int) floor(($actual->timestamp - $scheduledStart->timestamp) / 60);

        $rule = $rules->first(function (LatenessRule $r) use ($lateMinutes) {
            return $lateMinutes >= $r->from_minute
                && ($r->to_minute === null || $lateMinutes <= $r->to_minute);
        });

        if ($rule) {
            return new LatenessResult($lateMinutes, $rule->label, $rule->color, $rule->is_counted_late);
        }

        return new LatenessResult($lateMinutes, 'terlambat', 'red', true);
    }
}
