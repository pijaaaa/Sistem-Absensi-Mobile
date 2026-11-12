@extends('layouts.admin')

@section('title', 'Lokasi Absen')

@section('content')
<div class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
    <div>
        <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Data management</p>
        <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Lokasi Absen</h2>
        <p class="mt-1 text-sm text-gray-500">Kelola lokasi dan batas area untuk proses absensi.</p>
    </div>
    @can('locations.create')
        <a href="{{ route('locations.create') }}" class="inline-flex items-center justify-center rounded-lg bg-secondary px-4 py-2.5 text-sm font-bold text-neutral-dark shadow-sm hover:bg-amber-400">+ Tambah Lokasi</a>
    @endcan
</div>

<div class="overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <x-table :headers="[['label' => 'Aksi'], ['label' => 'Nama'], ['label' => 'Mode'], ['label' => 'Detail'], ['label' => 'Karyawan']]">
        @forelse ($locations as $location)
            <tr>
                <td class="px-4 py-2">
                    <div class="flex flex-wrap gap-2">
                        @can('locations.update')<a href="{{ route('locations.edit', $location) }}" class="inline-flex rounded-lg bg-primary px-3 py-1.5 text-sm font-semibold text-white hover:bg-primary/90">Ubah</a>@endcan
                        @can('locations.delete')
                            <x-modal :title="'Hapus ' . $location->name" trigger="Hapus"><p class="text-sm text-gray-600">Yakin hapus lokasi ini?</p><x-slot:actions><form method="POST" action="{{ route('locations.destroy', $location) }}">@csrf @method('DELETE')<button class="rounded-lg bg-red-600 px-3 py-1.5 text-sm text-white">Hapus</button></form></x-slot:actions></x-modal>
                        @endcan
                    </div>
                </td>
                <td class="px-4 py-2 font-bold text-neutral-dark">{{ $location->name }}</td>
                <td class="px-4 py-2">
                    <x-badge :color="['point' => 'blue', 'polygon' => 'green', 'off' => 'gray'][$location->mode]">
                        {{ $location->mode }}
                    </x-badge>
                </td>
                <td class="px-4 py-2 text-gray-500">
                    @if ($location->mode === 'point')
                        {{ $location->lat }}, {{ $location->lng }} · {{ $location->radius_m }} m
                    @elseif ($location->mode === 'polygon')
                        {{ count($location->polygon_json ?? []) }} titik
                    @else
                        Tanpa lokasi
                    @endif
                </td>
                <td class="px-4 py-2 font-semibold text-primary">{{ $location->employees_count }}</td>
            </tr>
        @empty
            <tr><td colspan="5" class="px-4 py-6 text-center text-gray-400">Belum ada data.</td></tr>
        @endforelse
    </x-table>
</div>
@endsection
