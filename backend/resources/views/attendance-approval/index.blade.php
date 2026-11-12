@extends('layouts.admin')

@section('title', 'Approval Kehadiran')

@section('content')
<div class="mb-7">
    <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Attendance approval</p>
    <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Approval Kehadiran</h2>
    <p class="mt-1 text-sm text-gray-500">Tinjau absensi dari device cadangan yang menunggu persetujuan.</p>
</div>

<div class="overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <x-table :headers="[['label' => 'Aksi'], ['label' => 'Karyawan'], ['label' => 'Department'], ['label' => 'Tanggal'], ['label' => 'Jam Masuk'], ['label' => 'Device']]">
        @forelse ($attendances as $attendance)
            <tr>
                <td class="px-4 py-2">
                    @can('attendance_approval.approve')
                        <div class="flex gap-1">
                            <form method="POST" action="{{ route('attendance-approval.approve', $attendance) }}">@csrf<button class="rounded-lg bg-primary px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-tertiary">Setujui</button></form>
                            <form method="POST" action="{{ route('attendance-approval.reject', $attendance) }}">@csrf<button class="rounded-lg bg-[#fde8e7] px-2.5 py-1.5 text-xs font-semibold text-[#b42318] hover:bg-red-100">Tolak</button></form>
                        </div>
                    @endcan
                </td>
                <td class="px-4 py-2 font-bold text-neutral-dark">{{ $attendance->employee?->name }}</td>
                <td class="px-4 py-2">{{ $attendance->employee?->department?->name }}</td>
                <td class="px-4 py-2">{{ $attendance->date->format('d M Y') }}</td>
                <td class="px-4 py-2">{{ $attendance->check_in_at?->format('H:i') ?? '-' }}</td>
                <td class="px-4 py-2"><x-badge color="yellow">Device cadangan</x-badge></td>
            </tr>
        @empty
            <tr><td colspan="6" class="px-4 py-12 text-center text-sm text-gray-400">Tidak ada approval kehadiran yang menunggu.</td></tr>
        @endforelse
    </x-table>
</div>

<div class="mt-4">{{ $attendances->links() }}</div>
@endsection
