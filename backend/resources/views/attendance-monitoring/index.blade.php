@extends('layouts.admin')

@section('title', 'Monitoring Absensi Harian')

@section('content')
<div class="mb-7">
    <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Attendance overview</p>
    <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Monitoring Absensi</h2>
    <p class="mt-1 text-sm text-gray-500">Pantau kehadiran karyawan secara real-time berdasarkan tanggal dan department.</p>
</div>

<form method="GET" data-auto-filter class="mb-5 flex flex-wrap items-end gap-3 rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Tanggal</label>
        <input type="date" name="date" value="{{ $date }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Department</label>
        <select name="department_id" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <option value="">Semua</option>
            @foreach ($departments as $department)
                <option value="{{ $department->id }}" @selected($departmentId == $department->id)>{{ $department->name }}</option>
            @endforeach
        </select>
    </div>
</form>

<div class="grid min-h-0 gap-4 md:grid-cols-2 xl:grid-cols-3">
    @foreach ($departmentSummaries as $summary)
        <section class="flex min-h-0 flex-col overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
            <div class="border-b border-[#edf2ee] p-4">
                <div class="flex items-center justify-between">
                    <h2 class="flex items-center gap-2 font-extrabold text-neutral-dark">
                        <span class="h-2 w-2 rounded-full bg-primary"></span>{{ $summary['department'] }}
                    </h2>
                    <span class="rounded-full bg-[#e4f3e9] px-2.5 py-1 text-[11px] font-bold text-primary">{{ $summary['present'] }}/{{ $summary['total'] }} hadir</span>
                </div>
                <div class="mt-3 h-1.5 rounded-full bg-[#e8f0ea]"><div class="h-1.5 rounded-full bg-primary" style="width: {{ $summary['total'] ? ($summary['present'] / $summary['total']) * 100 : 0 }}%"></div></div>
                <div class="mt-3 flex items-center justify-between text-[11px]">
                    <span class="rounded-md bg-[#fde8e7] px-2 py-1 font-semibold text-[#b42318]">Belum absen ({{ $summary['missing']->count() }})</span>
                    <span class="text-gray-500">{{ $summary['total'] ? round(($summary['present'] / $summary['total']) * 100) : 0 }}% Hadir</span>
                </div>
            </div>
            <div class="border-b border-[#edf2ee] px-3 py-2">
                <input type="search" placeholder="Cari nama / NIP {{ $summary['department'] }}..." class="w-full border-0 bg-[#eefaf2] px-3 py-2 text-xs focus:ring-0">
            </div>
            <div class="min-h-0 max-h-[calc(100vh-390px)] overflow-y-auto px-3">
                @forelse ($summary['employees'] as $employee)
                    @php($attendance = $attendances->get($employee->id))
                    <details class="group border-b border-[#f0f4f1] py-2.5 text-xs">
                        <summary class="flex cursor-pointer list-none items-center justify-between">
                            <span class="flex min-w-0 items-center gap-2">
                                <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-[#dceee2] text-[10px] font-bold text-primary">{{ Str::substr($employee->name, 0, 2) }}</span>
                                <span class="truncate font-semibold text-neutral-dark">{{ $employee->name }}</span>
                            </span>
                            <span class="ml-2 shrink-0 rounded bg-{{ $attendance?->check_in_at ? '[#e4f3e9]' : '[#fde8e7]' }} px-2 py-1 font-mono text-[9px] {{ $attendance?->check_in_at ? 'text-primary' : 'text-[#b42318]' }}">{{ $attendance?->check_in_at ? 'Hadir' : 'Belum absen' }}</span>
                        </summary>
                        <div class="mt-2 grid grid-cols-2 gap-2 rounded-lg bg-[#f8fbf9] p-2 text-[10px] text-gray-500">
                            <span>Masuk <strong class="block text-neutral-dark">{{ $attendance?->check_in_at?->format('H:i') ?? '-' }}</strong></span>
                            <span>Pulang <strong class="block text-neutral-dark">{{ $attendance?->check_out_at?->format('H:i') ?? '-' }}</strong></span>
                            <span>Status <strong class="block text-neutral-dark">{{ $attendance?->approval_status ?? 'Belum absen' }}</strong></span>
                            <span>Device <strong class="block text-neutral-dark">{{ $attendance?->device?->name ?? '-' }}</strong></span>
                        </div>
                    </details>
                @empty
                    <p class="py-8 text-center text-xs font-semibold text-primary">Tidak ada karyawan.</p>
                @endforelse
            </div>
            <footer class="mt-auto flex justify-between bg-[#f8fbf9] px-3 py-2 text-[11px] text-gray-500">
                <span>Department {{ $summary['department'] }}</span><span class="font-semibold text-red-600">Kehadiran: {{ $summary['total'] ? round(($summary['present'] / $summary['total']) * 100) : 0 }}%</span>
            </footer>
        </section>
    @endforeach
</div>
@endsection
