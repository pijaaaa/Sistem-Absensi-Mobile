@extends('layouts.admin')

@section('title', 'Dashboard')

@section('content')
@php
    $cards = [
        ['label' => 'Hadir hari ini', 'value' => $data['hadir'], 'color' => 'green'],
        ['label' => 'Telat', 'value' => $data['telat'], 'color' => 'yellow'],
        ['label' => 'Belum absen', 'value' => $data['belum'], 'color' => 'red'],
        ['label' => 'Cuti', 'value' => $data['cuti'], 'color' => 'blue'],
        ['label' => 'Sakit', 'value' => $data['sakit'], 'color' => 'gray'],
        ['label' => 'Izin', 'value' => $data['izin'], 'color' => 'gray'],
        ['label' => 'Dinas', 'value' => $data['dinas'], 'color' => 'blue'],
        ['label' => 'Total karyawan', 'value' => $data['active'], 'color' => 'gray'],
    ];
@endphp

<div class="mb-6 grid grid-cols-2 gap-3 md:grid-cols-4 xl:grid-cols-8">
    @foreach ($cards as $card)
        <div class="rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
            <div class="text-[11px] font-semibold leading-4 text-primary/60">{{ $card['label'] }}</div>
            <div class="mt-1 flex items-center gap-2">
                <span class="text-2xl font-extrabold tracking-tight text-neutral-dark">{{ $card['value'] }}</span>
                <x-badge :color="$card['color']">{{ $card['label'] }}</x-badge>
            </div>
        </div>
    @endforeach
</div>

<div class="mb-4 rounded-xl border border-[#dce7e0] bg-primary p-5 text-white shadow-[0_2px_8px_rgba(16,36,27,0.08)]">
    <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
            <p class="text-xs font-semibold uppercase tracking-[0.16em] text-white/60">Perlu perhatian</p>
            <h3 class="mt-1 text-lg font-bold">Approval kehadiran device cadangan</h3>
            <p class="mt-1 text-sm text-white/70">{{ $data['pendingApprovals'] }} absensi menunggu keputusan.</p>
        </div>
        @can('attendance_approval.view')
            <a href="{{ route('attendance-approval.index') }}" class="rounded-lg bg-white px-4 py-2 text-sm font-semibold text-primary hover:bg-gray-100">Buka approval</a>
        @endcan
    </div>
</div>

<div class="mb-4 grid grid-cols-1 gap-4 md:grid-cols-3">
    <div class="rounded-xl border border-[#dce7e0] bg-white p-5 shadow-[0_2px_8px_rgba(16,36,27,0.035)] md:col-span-2">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Kinerja hari ini</p>
                <h3 class="mt-1 text-lg font-bold text-neutral-dark">Persentase kehadiran</h3>
            </div>
            <span class="text-3xl font-extrabold text-primary">{{ $data['attendanceRate'] }}%</span>
        </div>
        <div class="mt-4 h-2 overflow-hidden rounded-full bg-[#e8f0eb]"><div class="h-full rounded-full bg-primary" style="width: {{ $data['attendanceRate'] }}%"></div></div>
        <p class="mt-2 text-xs text-gray-500">{{ $data['hadir'] }} dari {{ $data['active'] }} karyawan aktif sudah hadir.</p>
    </div>
    <div class="rounded-xl border border-[#dce7e0] bg-white p-5 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
        <p class="text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Aksi cepat</p>
        <div class="mt-3 grid gap-2 text-sm font-semibold">
            @can('employees.create')<a href="{{ route('employees.create') }}" class="rounded-lg bg-[#f1f7f3] px-3 py-2 text-primary hover:bg-[#e3f0e8]">+ Tambah karyawan</a>@endcan
            @can('attendance_approval.view')<a href="{{ route('attendance-approval.index') }}" class="rounded-lg bg-[#f1f7f3] px-3 py-2 text-primary hover:bg-[#e3f0e8]">+ Tinjau approval</a>@endcan
        </div>
    </div>
</div>

<div class="mb-4 grid grid-cols-1 gap-4 lg:grid-cols-2">
    <div class="rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
        <h3 class="mb-3 text-sm font-semibold">Aktivitas terbaru</h3>
        <div class="space-y-3">
            @forelse ($data['activities'] as $activity)
                <div class="flex items-start justify-between gap-3 text-sm">
                    <div><p class="font-semibold text-neutral-dark">{{ str_replace('_', ' ', $activity->action) }}</p><p class="text-xs text-gray-500">{{ $activity->actor?->name ?? 'Sistem' }}</p></div>
                    <span class="whitespace-nowrap text-xs text-gray-400">{{ $activity->created_at?->diffForHumans() }}</span>
                </div>
            @empty
                <p class="text-sm text-gray-400">Belum ada aktivitas.</p>
            @endforelse
        </div>
    </div>
    <div class="rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
        <h3 class="mb-3 text-sm font-semibold">Ringkasan status</h3>
        <div class="grid grid-cols-2 gap-3 text-sm">
            <div class="rounded-lg bg-[#f7faf8] p-3"><span class="text-gray-500">Hadir</span><strong class="mt-1 block text-lg">{{ $data['hadir'] }}</strong></div>
            <div class="rounded-lg bg-[#f7faf8] p-3"><span class="text-gray-500">Telat</span><strong class="mt-1 block text-lg">{{ $data['telat'] }}</strong></div>
            <div class="rounded-lg bg-[#f7faf8] p-3"><span class="text-gray-500">Belum absen</span><strong class="mt-1 block text-lg">{{ $data['belum'] }}</strong></div>
            <div class="rounded-lg bg-[#f7faf8] p-3"><span class="text-gray-500">Cuti/izin</span><strong class="mt-1 block text-lg">{{ $data['cuti'] + $data['izin'] }}</strong></div>
        </div>
    </div>
</div>

<div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
    <div class="rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
        <h3 class="mb-2 text-sm font-semibold">Tren Kehadiran 30 Hari</h3>
        <canvas id="trendChart" height="120"></canvas>
    </div>
    <div class="rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
        <h3 class="mb-2 text-sm font-semibold">Kehadiran per Department (hari ini)</h3>
        <canvas id="deptChart" height="120"></canvas>
    </div>
</div>

<div class="mt-4 overflow-x-auto rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <x-table :headers="[['label' => 'Lokasi'], ['label' => 'Hadir hari ini']]">
        @forelse ($data['perLocation'] as $row)
            <tr>
                <td class="px-4 py-2">{{ $row['name'] ?? $row->name ?? '' }}</td>
                <td class="px-4 py-2">{{ $row['total'] ?? $row->total ?? 0 }}</td>
            </tr>
        @empty
            <tr><td colspan="2" class="px-4 py-6 text-center text-gray-400">Belum ada data hari ini.</td></tr>
         @endforelse
    </x-table>
</div>
@endsection

@push('scripts')
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
    <script>
        const trend = @json($data['trend']);
        const perDept = @json($data['perDepartment']);

        new Chart(document.getElementById('trendChart'), {
            type: 'line',
            data: {
                labels: trend.map(t => t.date.slice(5)),
                datasets: [{ label: 'Hadir', data: trend.map(t => t.total), borderColor: '#1C4D3D', backgroundColor: 'rgba(28,77,61,0.1)', fill: true, tension: 0.3 }]
            },
            options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
        });

        new Chart(document.getElementById('deptChart'), {
            type: 'bar',
            data: {
                labels: perDept.map(d => d.name),
                datasets: [{ label: 'Hadir', data: perDept.map(d => d.total), backgroundColor: '#F59E0B' }]
            },
            options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
        });
    </script>
@endpush
