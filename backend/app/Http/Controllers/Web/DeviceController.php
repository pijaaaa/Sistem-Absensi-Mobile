<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class DeviceController extends Controller
{
    public function index(): View
    {
        $devices = Device::with('employee.department')->latest()->paginate(30);

        return view('devices.index', compact('devices'));
    }

    public function destroy(Device $device): RedirectResponse
    {
        $old = $device->getAttributes();
        $device->delete();
        AuditLogger::record('device.reset', null, $old, null);

        return back()->with('status', 'Device berhasil di-reset.');
    }
}
