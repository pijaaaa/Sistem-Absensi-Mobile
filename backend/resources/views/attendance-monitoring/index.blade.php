@extends('layouts.admin')

@section('title', 'Monitoring Absensi Harian')

@section('content')
<form method="GET" class="mb-4 flex flex-wrap items-end gap-3 rounded-xl border bg-white p-4">
    <div>
        <label class="mb-1 block text-sm font-medium">Tanggal</label>
        <input type="date" name="date" value="{{ $date }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <div>
        <label class="mb-1 block text-sm font-medium">Department</label>
        <select name="department_id" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <option value="">Semua</option>
            @foreach ($departments as $department)
                <option value="{{ $department->id }}" @selected($departmentId == $department->id)>{{ $department->name }}</option>
            @endforeach
        </select>
    </div>
    <button class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white">Tampilkan</button>
</form>

<div class="mb-4 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
    @foreach ($departmentSummaries as $summary)
        <div class="rounded-xl border bg-white p-4">
            <div class="flex items-center justify-between">
                <h2 class="font-semibold">{{ $summary['department'] }}</h2>
                <span class="text-sm text-gray-500">{{ $summary['present'] }}/{{ $summary['total'] }} hadir</span>
            </div>
            @if ($summary['missing']->isNotEmpty())
                <p class="mt-3 text-sm font-medium text-red-600">Belum absen ({{ $summary['missing']->count() }})</p>
                <ul class="mt-1 list-inside list-disc text-sm text-gray-600">
                    @foreach ($summary['missing'] as $employee)
                        <li>{{ $employee->name }} <span class="text-gray-400">{{ $employee->nip }}</span></li>
                    @endforeach
                </ul>
            @else
                <p class="mt-3 text-sm text-green-600">Semua karyawan sudah absen.</p>
            @endif
        </div>
    @endforeach
</div>

<div class="overflow-x-auto rounded-xl border bg-white">
    <x-table :headers="[['label' => 'Nama'], ['label' => 'Department'], ['label' => 'Lokasi'], ['label' => 'Masuk'], ['label' => 'Pulang'], ['label' => 'Status'], ['label' => 'Keterangan']]">
        @forelse ($employees as $employee)
            @php($attendance = $attendances->get($employee->id))
            <tr>
                <td class="px-4 py-2">{{ $employee->name }} <span class="text-gray-400">{{ $employee->nip }}</span></td>
                <td class="px-4 py-2">{{ $employee->department?->name }}</td>
                <td class="px-4 py-2">{{ $employee->workLocation?->name }}</td>
                <td class="px-4 py-2">{{ $attendance?->check_in_at?->format('H:i') ?? '-' }}</td>
                <td class="px-4 py-2">{{ $attendance?->check_out_at?->format('H:i') ?? '-' }}</td>
                <td class="px-4 py-2">
                    @if ($attendance?->check_in_at)
                        <span class="text-green-600">Hadir</span>
                    @else
                        <span class="text-red-600">Belum hadir</span>
                    @endif
                </td>
                <td class="px-4 py-2">{{ $attendance?->late_minutes > 0 ? 'Terlambat '.$attendance->late_minutes.' menit' : ($attendance?->is_dinas ? 'Dinas' : '-') }}</td>
            </tr>
        @empty
            <tr><td colspan="7" class="px-4 py-6 text-center text-gray-400">Tidak ada karyawan aktif.</td></tr>
        @endforelse
    </x-table>
</div>
@endsection
