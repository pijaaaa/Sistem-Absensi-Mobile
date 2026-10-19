@extends('layouts.admin')

@section('title', 'Laporan Absensi')

@section('content')
<form method="GET" class="mb-4 flex flex-wrap items-end gap-3 rounded-xl border bg-white p-4">
    <div>
        <label class="mb-1 block text-sm font-medium">Dari</label>
        <input type="date" name="from" value="{{ $from->toDateString() }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <div>
        <label class="mb-1 block text-sm font-medium">Sampai</label>
        <input type="date" name="to" value="{{ $to->toDateString() }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <div>
        <label class="mb-1 block text-sm font-medium">Department</label>
        <select name="department_id" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <option value="">Semua</option>
            @foreach ($departments as $department)
                <option value="{{ $department->id }}" @selected(($filters['department_id'] ?? null) == $department->id)>{{ $department->name }}</option>
            @endforeach
        </select>
    </div>
    <div>
        <label class="mb-1 block text-sm font-medium">Lokasi</label>
        <select name="location_id" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <option value="">Semua</option>
            @foreach ($locations as $location)
                <option value="{{ $location->id }}" @selected(($filters['location_id'] ?? null) == $location->id)>{{ $location->name }}</option>
            @endforeach
        </select>
    </div>
    <button class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white">Tampilkan</button>

    @can('attendance_reports.export')
        <a href="{{ route('reports.export', ['format' => 'excel'] + $filters) }}" class="rounded-lg border px-4 py-2 text-sm">Ekspor Excel</a>
        <a href="{{ route('reports.export', ['format' => 'pdf'] + $filters) }}" class="rounded-lg border px-4 py-2 text-sm">Ekspor PDF</a>
    @endcan
</form>

<div class="overflow-x-auto rounded-xl border bg-white">
    <x-table :headers="[['label' => 'Nama'], ['label' => 'Department'], ['label' => 'Lokasi'], ['label' => 'Hadir'], ['label' => 'Telat'], ['label' => 'Menit Telat'], ['label' => 'Alfa'], ['label' => 'Cuti'], ['label' => 'Sakit'], ['label' => 'Izin'], ['label' => 'Dinas']]">
        @forelse ($recap as $employee)
            <tr>
                <td class="px-4 py-2">{{ $employee->name }} <span class="text-gray-400">{{ $employee->nip }}</span></td>
                <td class="px-4 py-2">{{ $employee->department?->name }}</td>
                <td class="px-4 py-2">{{ $employee->workLocation?->name }}</td>
                <td class="px-4 py-2">{{ $employee->stats['hadir'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['telat'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['total_menit_telat'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['alfa'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['cuti'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['sakit'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['izin'] }}</td>
                <td class="px-4 py-2">{{ $employee->stats['dinas'] }}</td>
            </tr>
        @empty
            <tr><td colspan="11" class="px-4 py-6 text-center text-gray-400">Tidak ada data.</td></tr>
        @endforelse
    </x-table>
</div>

<div class="mt-4">{{ $recap->links() }}</div>
@endsection
