@extends('layouts.admin')

@section('title', 'Tanggal Merah')

@section('content')
<div class="mb-4 flex items-center justify-between">
    <form method="GET" class="flex items-center gap-2">
        <label class="text-sm">Tahun</label>
        <input type="number" name="year" value="{{ $year }}" class="w-28 rounded-lg border border-gray-300 px-3 py-2 text-sm">
        <button class="rounded-lg border px-3 py-2 text-sm">Tampilkan</button>
    </form>
</div>

@can('holidays.create')
    <form method="POST" action="{{ route('holidays.store') }}" class="mb-4 flex flex-wrap items-end gap-3 rounded-xl border bg-white p-4">
        @csrf
        <div>
            <label class="mb-1 block text-sm font-medium">Tanggal</label>
            <input type="date" name="date" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('date') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <div>
            <label class="mb-1 block text-sm font-medium">Nama</label>
            <input type="text" name="name" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('name') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <button class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Tambah</button>
    </form>
@endcan

<div class="overflow-x-auto rounded-xl border bg-white">
    <x-table :headers="[['label' => 'Tanggal'], ['label' => 'Nama'], ['label' => 'Aksi']]">
        @forelse ($holidays as $holiday)
            <tr>
                <td class="px-4 py-2">{{ $holiday->date->format('d M Y') }}</td>
                <td class="px-4 py-2">{{ $holiday->name }}</td>
                <td class="px-4 py-2 text-right">
                    @can('holidays.delete')
                        <x-modal :title="'Hapus ' . $holiday->name" trigger="Hapus">
                            <p class="text-sm text-gray-600">Yakin hapus tanggal merah ini?</p>
                            <x-slot:actions>
                                <form method="POST" action="{{ route('holidays.destroy', $holiday) }}">
                                    @csrf @method('DELETE')
                                    <button class="rounded-lg bg-red-600 px-3 py-1.5 text-sm text-white">Hapus</button>
                                </form>
                            </x-slot:actions>
                        </x-modal>
                    @endcan
                </td>
            </tr>
        @empty
            <tr><td colspan="3" class="px-4 py-6 text-center text-gray-400">Belum ada tanggal merah tahun ini.</td></tr>
        @endforelse
    </x-table>
</div>
@endsection
