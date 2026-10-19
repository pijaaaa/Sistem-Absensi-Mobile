@extends('layouts.admin')

@section('title', 'Manajemen Menu')

@section('content')
<form method="POST" action="{{ route('menus.index') }}" x-data>
    @csrf

    @foreach (['web' => $web, 'mobile' => $mobile] as $platform => $items)
        <div class="mb-6 overflow-hidden rounded-xl border bg-white">
            <div class="border-b bg-gray-50 px-4 py-2 text-sm font-semibold capitalize">Menu {{ $platform }}</div>
            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="border-b text-left text-xs uppercase text-gray-400">
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
                            <tr class="border-b last:border-0">
                                <td class="px-4 py-2">
                                    <input name="menus[{{ $menu->id }}][label]" value="{{ $menu->label }}"
                                        class="w-full rounded border border-gray-300 px-2 py-1">
                                </td>
                                <td class="px-4 py-2">
                                    <input name="menus[{{ $menu->id }}][icon]" value="{{ $menu->icon }}"
                                        class="w-32 rounded border border-gray-300 px-2 py-1">
                                </td>
                                <td class="px-4 py-2 text-gray-500">{{ $menu->module->key }}</td>
                                <td class="px-4 py-2 text-gray-500">{{ $menu->route_or_feature_key }}</td>
                                <td class="px-4 py-2">
                                    <input type="number" name="menus[{{ $menu->id }}][sort_order]" value="{{ $menu->sort_order }}"
                                        class="w-20 rounded border border-gray-300 px-2 py-1">
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

    <button type="submit" class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">
        Simpan
    </button>
</form>
@endsection
