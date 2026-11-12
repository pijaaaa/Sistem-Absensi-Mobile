@extends('layouts.admin')

@section('title', 'Tanggal Merah')

@section('content')
<div class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
    <div>
        <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Calendar management</p>
        <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Tanggal Merah</h2>
        <p class="mt-1 text-sm text-gray-500">Kelola hari libur dan tanggal merah perusahaan.</p>
    </div>
    <form method="GET" data-auto-filter class="flex flex-wrap items-end gap-2">
        <div>
            <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Tahun</label>
            <input type="number" name="year" value="{{ $year }}" class="w-28 rounded-lg border border-gray-300 px-3 py-2.5 text-sm">
        </div>
        <div>
            <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Cari</label>
            <input type="search" name="search" value="{{ $search }}" placeholder="Nama hari libur" class="w-48 rounded-lg border border-gray-300 px-3 py-2.5 text-sm">
        </div>
    </form>
</div>

@can('holidays.create')
    <form method="POST" action="{{ route('holidays.store') }}" class="mb-5 flex flex-wrap items-end gap-4 rounded-xl border border-[#dce7e0] bg-white p-5 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
        @csrf
        <div>
            <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Tanggal</label>
            <input type="date" name="date" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('date') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <div>
            <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Nama Hari Libur</label>
            <input type="text" name="name" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('name') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <button class="rounded-lg bg-secondary px-4 py-2.5 text-sm font-bold text-neutral-dark shadow-sm hover:bg-amber-400">+ Tambah Tanggal</button>
    </form>
@endcan

<div class="overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <x-table :headers="[['label' => 'Aksi'], ['label' => 'Tanggal'], ['label' => 'Nama']]">
        @forelse ($holidays as $holiday)
            <tr>
                <td class="px-4 py-2">
                    @can('holidays.delete')
                        <x-modal :title="'Hapus ' . $holiday->name" trigger="Hapus"><p class="text-sm text-gray-600">Yakin hapus tanggal merah ini?</p><x-slot:actions><form method="POST" action="{{ route('holidays.destroy', $holiday) }}">@csrf @method('DELETE')<button class="rounded-lg bg-red-600 px-3 py-1.5 text-sm font-semibold text-white">Hapus</button></form></x-slot:actions></x-modal>
                    @endcan
                </td>
                <td class="px-4 py-2 font-bold text-primary">{{ $holiday->date->format('d M Y') }}</td>
                <td class="px-4 py-2 font-semibold text-neutral-dark">{{ $holiday->name }}</td>
            </tr>
        @empty
            <tr><td colspan="3" class="px-4 py-6 text-center text-gray-400">Belum ada tanggal merah tahun ini.</td></tr>
        @endforelse
    </x-table>
</div>
@endsection
