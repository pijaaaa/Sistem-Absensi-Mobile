<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmployeeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'nip' => $this->nip,
            'name' => $this->name,
            'is_active' => $this->is_active,
            'department' => new DepartmentResource($this->whenLoaded('department')),
            'work_location' => new WorkLocationResource($this->whenLoaded('workLocation')),
        ];
    }
}
