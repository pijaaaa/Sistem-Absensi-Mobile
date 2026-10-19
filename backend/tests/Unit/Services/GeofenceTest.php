<?php

namespace Tests\Unit\Services;

use App\Models\WorkLocation;
use App\Services\GeofenceService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GeofenceTest extends TestCase
{
    use RefreshDatabase;

    public function test_off_mode_always_passes(): void
    {
        $service = new GeofenceService;
        $loc = WorkLocation::create(['name' => 'Off', 'mode' => 'off']);

        $this->assertTrue($service->check($loc, -6.2, 106.8));
    }

    public function test_point_inside_radius_and_boundary_and_outside(): void
    {
        $service = new GeofenceService;
        $lat = -6.2;
        $lng = 106.8;
        $loc = WorkLocation::create([
            'name' => 'Pusat',
            'mode' => 'point',
            'lat' => $lat,
            'lng' => $lng,
            'radius_m' => 1000,
        ]);

        // titik tengah = 0 m.
        $this->assertTrue($service->check($loc, $lat, $lng));

        // seberapa tepat di batas: set radius = round(haversine(point, center)).
        $pLat = $lat + 0.01; // ~1113 m
        $boundaryRadius = (int) round($service->haversineMeters($pLat, $lng, $lat, $lng));
        $loc->update(['radius_m' => $boundaryRadius]);
        $this->assertTrue($service->check($loc, $pLat, $lng)); // inklusif <=

        $loc->update(['radius_m' => $boundaryRadius - 1]);
        $this->assertFalse($service->check($loc, $pLat, $lng));

        // jauh di luar.
        $this->assertFalse($service->check($loc->replicate()->forceFill(['radius_m' => 10]), $lat + 1, $lng));
    }

    public function test_polygon_inside_outside_and_notch(): void
    {
        $service = new GeofenceService;
        // L-shape concave: [lat,lng]
        $polygon = [
            [0, 0], [0, 10], [10, 10], [10, 5], [5, 5], [5, 0],
        ];
        $loc = WorkLocation::create([
            'name' => 'L', 'mode' => 'polygon',
            'polygon_json' => $polygon,
        ]);

        // (7,7): y=7 di [5,10] sehingga x boleh 0..10 -> dalam.
        $this->assertTrue($service->check($loc, 7, 7));
        // (7,2): y=2 di [0,5] sehingga x harus <=5 -> 7 di luar (notch).
        $this->assertFalse($service->check($loc, 7, 2));
        // (1,1) dalam.
        $this->assertTrue($service->check($loc, 1, 1));
        // kurang dari 3 titik -> selalu false.
        $loc2 = WorkLocation::create(['name' => 'Bad', 'mode' => 'polygon', 'polygon_json' => [[0, 0], [0, 1]]]);
        $this->assertFalse($service->check($loc2, 0, 0));
    }

    public function test_haversine_distances_pole_and_zero(): void
    {
        $service = new GeofenceService;

        $this->assertSame(0.0, round($service->haversineMeters(0, 0, 0, 0), 6));
        // equator dengan R=6371 km: 1 derajat lng ~111195 m.
        $this->assertEqualsWithDelta(111195, $service->haversineMeters(0, 0, 0, 1), 20);
    }
}
