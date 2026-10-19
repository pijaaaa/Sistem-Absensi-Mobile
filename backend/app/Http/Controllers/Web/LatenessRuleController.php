<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LatenessRule;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class LatenessRuleController extends Controller
{
    public function edit(): View
    {
        $rules = LatenessRule::orderBy('from_minute')->get();

        return view('lateness.edit', compact('rules'));
    }

    public function update(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'rules' => ['required', 'array'],
            'rules.*.label' => ['required', 'string', 'max:50'],
            'rules.*.from_minute' => ['required', 'integer', 'min:0'],
            'rules.*.to_minute' => ['nullable', 'integer', 'min:0'],
            'rules.*.color' => ['required', 'string', 'max:20'],
            'rules.*.is_counted_late' => ['nullable'],
        ]);

        $old = LatenessRule::query()->get()->toArray();

        foreach ($data['rules'] as $id => $rule) {
            LatenessRule::whereKey($id)->update([
                'label' => $rule['label'],
                'from_minute' => $rule['from_minute'],
                'to_minute' => $rule['to_minute'] ?? null,
                'color' => $rule['color'],
                'is_counted_late' => ! empty($rule['is_counted_late']),
            ]);
        }

        AuditLogger::record('lateness.updated', null, ['rules' => $old], [
            'rules' => LatenessRule::query()->get()->toArray(),
        ]);

        return redirect()->route('lateness.index')->with('status', 'Aturan keterlambatan disimpan.');
    }
}
