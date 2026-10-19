<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use App\Support\Access\MenuService;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class MenuController extends Controller
{
    public function __construct(private MenuService $menus) {}

    public function index(): View
    {
        $web = Menu::with('module')->where('platform', 'web')->orderBy('sort_order')->get();
        $mobile = Menu::with('module')->where('platform', 'mobile')->orderBy('sort_order')->get();

        return view('menus.index', compact('web', 'mobile'));
    }

    public function update(Request $request): RedirectResponse
    {
        $rows = $request->input('menus', []);
        $old = Menu::query()->get(['id', 'label', 'icon', 'sort_order', 'is_active'])->toArray();

        foreach ($rows as $id => $data) {
            $menu = Menu::find($id);

            if (! $menu) {
                continue;
            }

            $menu->update([
                'label' => $data['label'] ?? $menu->label,
                'icon' => $data['icon'] ?? $menu->icon,
                'sort_order' => (int) ($data['sort_order'] ?? $menu->sort_order),
                'is_active' => $menu->is_locked ? true : ! empty($data['is_active']),
            ]);
        }

        AuditLogger::record('menus.updated', null, ['menus' => $old], [
            'menus' => Menu::query()->get(['id', 'label', 'icon', 'sort_order', 'is_active'])->toArray(),
        ]);
        $this->menus->flushAll();

        return redirect()->route('menus.index')->with('status', 'Menu berhasil disimpan.');
    }
}
