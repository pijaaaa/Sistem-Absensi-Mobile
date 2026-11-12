@extends('layouts.admin')

@section('title', 'Laporan Absensi')

@section('content')
<div class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
    <div>
        <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Reports & analytics</p>
        <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Laporan Absensi</h2>
        <p class="mt-1 text-sm text-gray-500">Ringkasan kehadiran karyawan berdasarkan periode dan lokasi.</p>
    </div>
</div>

<form method="GET" data-auto-filter class="mb-5 flex flex-wrap items-end gap-3 rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Dari</label>
        <input type="date" name="from" value="{{ $from->toDateString() }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Sampai</label>
        <input type="date" name="to" value="{{ $to->toDateString() }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Department</label>
        <select name="department_id" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <option value="">Semua</option>
            @foreach ($departments as $department)
                <option value="{{ $department->id }}" @selected(($filters['department_id'] ?? null) == $department->id)>{{ $department->name }}</option>
            @endforeach
        </select>
    </div>
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Lokasi</label>
        <select name="location_id" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <option value="">Semua</option>
            @foreach ($locations as $location)
                <option value="{{ $location->id }}" @selected(($filters['location_id'] ?? null) == $location->id)>{{ $location->name }}</option>
            @endforeach
        </select>
    </div>

    @can('attendance_reports.export')
        <a href="{{ route('reports.export', ['format' => 'excel'] + $filters) }}" class="rounded-lg border border-[#cddbd2] px-4 py-2.5 text-sm font-semibold text-primary hover:bg-[#edf4ef]">Ekspor Excel</a>
        <a href="{{ route('reports.export', ['format' => 'pdf'] + $filters) }}" class="rounded-lg border border-[#cddbd2] px-4 py-2.5 text-sm font-semibold text-primary hover:bg-[#edf4ef]">Ekspor PDF</a>
    @endcan
</form>

<div class="overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <x-table :headers="[['label' => 'Nama'], ['label' => 'Department'], ['label' => 'Lokasi'], ['label' => 'Hadir'], ['label' => 'Telat'], ['label' => 'Alfa'], ['label' => 'Cuti'], ['label' => 'Sakit'], ['label' => 'Izin'], ['label' => 'Dinas']]">
        @forelse ($recap as $employee)
            <tr>
                <td class="px-4 py-2 font-bold text-neutral-dark">{{ $employee->name }} <span class="font-normal text-gray-400">{{ $employee->nip }}</span></td>
                <td class="px-4 py-2">{{ $employee->department?->name }}</td>
                <td class="px-4 py-2">{{ $employee->workLocation?->name }}</td>
                <td class="px-4 py-2">{{ $employee->stats['hadir'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['telat'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['alfa'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['cuti'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['sakit'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['izin'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['dinas'] }}</td>
            </tr>
        @empty
            <tr><td colspan="10" class="px-4 py-6 text-center text-gray-400">Tidak ada data.</td></tr>
        @endforelse
    </x-table>
</div>

<div class="mt-4">{{ $recap->links() }}</div>
@endsection
