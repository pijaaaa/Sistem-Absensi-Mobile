<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class WorkLocationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'mode' => $this->mode,
            'lat' => $this->lat,
            'lng' => $this->lng,
            'radius_m' => $this->radius_m,
            'polygon_json' => $this->polygon_json,
        ];
    }
}
