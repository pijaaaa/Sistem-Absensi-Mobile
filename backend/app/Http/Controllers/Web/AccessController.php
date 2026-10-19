<?php

namespace App\Http\Controllers\Web;

use App\Enums\Role;
use App\Http\Controllers\Controller;
use App\Models\Module;
use App\Support\Access\PermissionService;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AccessController extends Controller
{
    public function __construct(private PermissionService $permissions) {}

    public function index(): View
    {
        $modules = Module::with('permissions')->orderBy('sort_order')->get();

        $roles = collect(Role::cases())->mapWithKeys(function (Role $role) {
            return [$role->value => [
                'label' => $role->label(),
                'granted' => $this->permissions->granted($role->value),
            ]];
        });

        return view('access.index', compact('modules', 'roles'));
    }

    public function update(Request $request): RedirectResponse
    {
        $submitted = $request->input('matrix', []);
        $old = [];

        foreach (Role::cases() as $role) {
            $roleValue = $role->value;
            $current = $this->permissions->granted($roleValue);
            $old[$roleValue] = $current->all();

            $desired = array_keys($submitted[$roleValue] ?? []);

            foreach ($this->permissions->allKeys() as $key) {
                if ($this->permissions->isLocked($roleValue, $key)) {
                    continue;
                }

                if (in_array($key, $desired, true)) {
                    $this->permissions->grant($roleValue, $key);
                } else {
                    $this->permissions->revoke($roleValue, $key);
                }
            }
        }

        $new = [];
        foreach (Role::cases() as $role) {
            $new[$role->value] = $this->permissions->granted($role->value)->all();
        }

        AuditLogger::record('access.updated', null, $old, $new);
        $this->permissions->flushAll();

        return redirect()->route('access.index')->with('status', 'Izin berhasil disimpan.');
    }
}
