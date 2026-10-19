@extends('layouts.admin')

@section('title', 'Lokasi Absen')

@section('content')
<div class="mb-4 flex items-center justify-between">
    <h2 class="text-lg font-semibold">Daftar Lokasi</h2>
    @can('locations.create')
        <a href="{{ route('locations.create') }}"
            class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Tambah</a>
    @endcan
</div>

<div class="overflow-x-auto rounded-xl border bg-white">
    <x-table :headers="[['label' => 'Nama'], ['label' => 'Mode'], ['label' => 'Detail'], ['label' => 'Karyawan'], ['label' => 'Aksi']]">
        @forelse ($locations as $location)
            <tr>
                <td class="px-4 py-2">{{ $location->name }}</td>
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
                <td class="px-4 py-2">{{ $location->employees_count }}</td>
                <td class="px-4 py-2 text-right">
                    @can('locations.update')
                        <a href="{{ route('locations.edit', $location) }}" class="text-sm text-blue-600 hover:underline">Ubah</a>
                    @endcan
                    @can('locations.delete')
                        <x-modal :title="'Hapus ' . $location->name" trigger="Hapus">
                            <p class="text-sm text-gray-600">Yakin hapus lokasi ini?</p>
                            <x-slot:actions>
                                <form method="POST" action="{{ route('locations.destroy', $location) }}">
                                    @csrf @method('DELETE')
                                    <button class="rounded-lg bg-red-600 px-3 py-1.5 text-sm text-white">Hapus</button>
                                </form>
                            </x-slot:actions>
                        </x-modal>
                    @endcan
                </td>
            </tr>
        @empty
            <tr><td colspan="5" class="px-4 py-6 text-center text-gray-400">Belum ada data.</td></tr>
        @endforelse
    </x-table>
</div>
@endsection
