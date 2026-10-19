<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\Access\MenuService;
use App\Support\Access\PermissionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MeController extends Controller
{
    public function __construct(
        private PermissionService $permissions,
        private MenuService $menus,
    ) {}

    public function menus(Request $request): JsonResponse
    {
        $user = $request->user();

        $menus = $this->menus->forRole($user->role, 'mobile')->map(fn ($menu) => [
            'id' => $menu->id,
            'label' => $menu->label,
            'icon' => $menu->icon,
            'feature_key' => $menu->route_or_feature_key,
            'module' => $menu->module->key,
            'parent_id' => $menu->parent_id,
            'sort_order' => $menu->sort_order,
        ])->values();

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $menus,
        ]);
    }

    public function permissions(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => [
                'is_superadmin' => $user->isSuperadmin(),
                'keys' => array_values($this->permissions->keysForRole($user->role)),
            ],
        ]);
    }
}
