<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\Web\LocationRequest;
use App\Models\WorkLocation;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class LocationController extends Controller
{
    public function index(): View
    {
        $locations = WorkLocation::withCount('employees')->orderBy('name')->get();

        return view('locations.index', compact('locations'));
    }

    public function create(): View
    {
        return view('locations.form', ['location' => new WorkLocation]);
    }

    public function store(LocationRequest $request): RedirectResponse
    {
        $location = WorkLocation::create($this->payload($request));
        AuditLogger::record('created', $location, null, $location->getAttributes());

        return redirect()->route('locations.index')->with('status', 'Lokasi dibuat.');
    }

    public function edit(WorkLocation $location): View
    {
        return view('locations.form', compact('location'));
    }

    public function update(LocationRequest $request, WorkLocation $location): RedirectResponse
    {
        $old = $location->getAttributes();
        $location->update($this->payload($request));
        AuditLogger::record('updated', $location, $old, $location->getChanges());

        return redirect()->route('locations.index')->with('status', 'Lokasi diperbarui.');
    }

    public function destroy(WorkLocation $location): RedirectResponse
    {
        $old = $location->getAttributes();
        $location->delete();
        AuditLogger::record('deleted', $location, $old, null);

        return redirect()->route('locations.index')->with('status', 'Lokasi dihapus.');
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(LocationRequest $request): array
    {
        $data = $request->validated();

        if ($data['mode'] !== 'point') {
            $data['lat'] = $data['lng'] = $data['radius_m'] = null;
        }

        if ($data['mode'] !== 'polygon') {
            $data['polygon_json'] = null;
        }

        return $data;
    }
}
