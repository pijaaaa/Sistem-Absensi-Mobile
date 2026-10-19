<?php

namespace App\Services;

use App\Models\WorkLocation;

class GeofenceService
{
    /** Radius 1 meter toleransi di pinggir polygon. */
    public function check(WorkLocation $location, float $lat, float $lng): bool
    {
        return match ($location->mode) {
            'off' => true,
            'point' => $this->withinRadius($lat, $lng, $location->lat, $location->lng, $location->radius_m),
            'polygon' => $this->pointInPolygon($lat, $lng, $location->polygon_json),
            default => false,
        };
    }

    public function haversineMeters(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $r = 6371000;
        $aLat = deg2rad($lat2 - $lat1);
        $aLon = deg2rad($lng2 - $lng1);
        $a = sin($aLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($aLon / 2) ** 2;

        return 2 * $r * asin(sqrt($a));
    }

    public function withinRadius(
        float $lat, float $lng, ?float $centerLat, ?float $centerLng, ?int $radiusM
    ): bool {
        if ($centerLat === null || $centerLng === null || $radiusM === null) {
            return false;
        }

        return $this->haversineMeters($lat, $lng, $centerLat, $centerLng) <= $radiusM;
    }

    /**
     * Ray casting point-in-polygon. Polygon berupa array [[lat,lng], ...].
     */
    public function pointInPolygon(float $lat, float $lng, ?array $polygon): bool
    {
        if (! $polygon || count($polygon) < 3) {
            return false;
        }

        $inside = false;
        $n = count($polygon);
        [$x, $y] = [$lat, $lng];

        for ($i = 0, $j = $n - 1; $i < $n; $j = $i++) {
            [$xi, $yi] = $polygon[$i];
            [$xj, $yj] = $polygon[$j];

            $intersect = (($yi > $y) !== ($yj > $y))
                && ($x < ($xj - $xi) * ($y - $yi) / ($yj - $yi + 1e-12) + $xi);

            if ($intersect) {
                $inside = ! $inside;
            }
        }

        return $inside;
    }
}
