@extends('layouts.admin')

@section('title', 'Device')

@section('content')
<div class="mb-7">
    <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Device management</p>
    <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Device Terdaftar</h2>
    <p class="mt-1 text-sm text-gray-500">Kelola perangkat yang terhubung dengan akun karyawan.</p>
</div>

<div class="overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <x-table :headers="[['label' => 'Aksi'], ['label' => 'Karyawan'], ['label' => 'Department'], ['label' => 'Device'], ['label' => 'UID'], ['label' => 'Tipe'], ['label' => 'Status'], ['label' => 'Terdaftar']]">
        @forelse ($devices as $device)
            <tr>
                <td class="px-4 py-2">
                    @can('devices.update')
                        <x-modal :title="'Reset device ' . $device->employee?->name" trigger="Reset"><p class="text-sm text-gray-600">Hapus binding device ini? Karyawan bisa mendaftarkan device baru saat login berikutnya.</p><x-slot:actions><form method="POST" action="{{ route('devices.destroy', $device) }}">@csrf @method('DELETE')<button class="rounded-lg bg-[#fde8e7] px-3 py-1.5 text-sm font-semibold text-[#b42318] hover:bg-red-100">Reset</button></form></x-slot:actions></x-modal>
                    @endcan
                </td>
                <td class="px-4 py-2 font-bold text-neutral-dark">{{ $device->employee?->name }}</td>
                <td class="px-4 py-2">{{ $device->employee?->department?->name }}</td>
                <td class="px-4 py-2 font-semibold text-primary">{{ $device->name }}</td>
                <td class="px-4 py-2 text-gray-500">{{ $device->device_uid }}</td>
                <td class="px-4 py-2">
                    <x-badge :color="$device->type === 'primary' ? 'blue' : 'gray'">{{ $device->type }}</x-badge>
                </td>
                <td class="px-4 py-2">
                    <x-badge :color="$device->status === 'active' ? 'green' : 'red'">{{ $device->status }}</x-badge>
                </td>
                <td class="px-4 py-2">{{ $device->registered_at?->format('d M Y') }}</td>
            </tr>
        @empty
            <tr><td colspan="8" class="px-4 py-6 text-center text-gray-400">Belum ada device.</td></tr>
        @endforelse
    </x-table>
</div>

<div class="mt-4 flex flex-col gap-2 text-xs text-gray-500 sm:flex-row sm:items-center sm:justify-between">
    <span>Device terdaftar: {{ $devices->total() }}</span>
    <div>{{ $devices->links() }}</div>
</div>
@endsection
