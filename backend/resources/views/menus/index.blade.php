@extends('layouts.admin')

@section('title', 'Manajemen Menu')

@section('content')
<div class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
    <div>
        <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Administration</p>
        <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Manajemen Menu</h2>
        <p class="mt-1 text-sm text-gray-500">Atur tampilan menu berdasarkan platform.</p>
    </div>
</div>

<form method="POST" action="{{ route('menus.index') }}" x-data>
    @csrf

    @foreach (['web' => $web, 'mobile' => $mobile] as $platform => $items)
        <div class="mb-5 overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
            <div class="flex items-center justify-between border-b border-[#edf2ee] bg-[#f7faf8] px-5 py-4">
                <div>
                    <h3 class="text-sm font-extrabold capitalize text-neutral-dark">Menu {{ $platform }}</h3>
                    <p class="mt-0.5 text-xs text-gray-500">Konfigurasi navigasi {{ $platform }}</p>
                </div>
                <span class="rounded-full bg-[#e4f3e9] px-2.5 py-1 text-[10px] font-bold uppercase tracking-wide text-primary">{{ count($items) }} menu</span>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="border-b border-[#edf2ee] bg-white text-left text-[10px] font-bold uppercase tracking-wide text-primary/60">
                            <th class="px-4 py-2">Label</th>
                            <th class="px-4 py-2">Ikon</th>
                            <th class="px-4 py-2">Modul</th>
                            <th class="px-4 py-2">Kunci</th>
                            <th class="px-4 py-2">Urutan</th>
                            <th class="px-4 py-2">Aktif</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($items as $menu)
                            <tr class="border-b border-[#edf2ee] last:border-0 hover:bg-[#f8fbf9]">
                                <td class="px-4 py-2">
                                    <input name="menus[{{ $menu->id }}][label]" value="{{ $menu->label }}"
                                        class="w-full rounded-lg border border-[#cddbd2] bg-[#fbfdfb] px-2.5 py-1.5 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/10">
                                </td>
                                <td class="px-4 py-2">
                                    <input name="menus[{{ $menu->id }}][icon]" value="{{ $menu->icon }}"
                                        class="w-32 rounded-lg border border-[#cddbd2] bg-[#fbfdfb] px-2.5 py-1.5 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/10">
                                </td>
                                <td class="px-4 py-2 text-gray-500">{{ $menu->module->key }}</td>
                                <td class="px-4 py-2 text-gray-500">{{ $menu->route_or_feature_key }}</td>
                                <td class="px-4 py-2">
                                    <input type="number" name="menus[{{ $menu->id }}][sort_order]" value="{{ $menu->sort_order }}"
                                        class="w-20 rounded-lg border border-[#cddbd2] bg-[#fbfdfb] px-2.5 py-1.5 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/10">
                                </td>
                                <td class="px-4 py-2">
                                    <input type="checkbox" name="menus[{{ $menu->id }}][is_active]" value="1"
                                        {{ $menu->is_active ? 'checked' : '' }} {{ $menu->is_locked ? 'disabled' : '' }}>
                                    @if ($menu->is_locked)
                                        <input type="hidden" name="menus[{{ $menu->id }}][is_active]" value="1">
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    @endforeach

    <button type="submit" class="rounded-lg bg-secondary px-5 py-2.5 text-sm font-bold text-neutral-dark shadow-sm hover:bg-amber-400">
        Simpan Perubahan
    </button>
</form>
@endsection
