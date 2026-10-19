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

<div class="mb-6 grid grid-cols-2 gap-4 md:grid-cols-4">
    @foreach ($cards as $card)
        <div class="rounded-xl border bg-white p-4">
            <div class="text-sm text-gray-500">{{ $card['label'] }}</div>
            <div class="mt-1 flex items-center gap-2">
                <span class="text-2xl font-semibold">{{ $card['value'] }}</span>
                <x-badge :color="$card['color']">{{ $card['label'] }}</x-badge>
            </div>
        </div>
    @endforeach
</div>

<div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
    <div class="rounded-xl border bg-white p-4">
        <h3 class="mb-2 text-sm font-semibold">Tren Kehadiran 30 Hari</h3>
        <canvas id="trendChart" height="120"></canvas>
    </div>
    <div class="rounded-xl border bg-white p-4">
        <h3 class="mb-2 text-sm font-semibold">Kehadiran per Department (hari ini)</h3>
        <canvas id="deptChart" height="120"></canvas>
    </div>
</div>

<div class="mt-4 overflow-x-auto rounded-xl border bg-white">
    <x-table :headers="[['label' => 'Lokasi'], ['label' => 'Hadir hari ini']]">
        @forelse ($data['perLocation'] as $row)
            <tr>
                <td class="px-4 py-2">{{ $row->name }}</td>
                <td class="px-4 py-2">{{ $row->total }}</td>
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
                datasets: [{ label: 'Hadir', data: trend.map(t => t.total), borderColor: '#111827', backgroundColor: 'rgba(17,24,39,0.1)', fill: true, tension: 0.3 }]
            },
            options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
        });

        new Chart(document.getElementById('deptChart'), {
            type: 'bar',
            data: {
                labels: perDept.map(d => d.name),
                datasets: [{ label: 'Hadir', data: perDept.map(d => d.total), backgroundColor: '#3b82f6' }]
            },
            options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
        });
    </script>
@endpush
