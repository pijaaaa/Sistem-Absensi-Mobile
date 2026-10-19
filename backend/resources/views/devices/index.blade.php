@extends('layouts.admin')

@section('title', 'Device')

@section('content')
<div class="overflow-x-auto rounded-xl border bg-white">
    <x-table :headers="[['label' => 'Karyawan'], ['label' => 'Department'], ['label' => 'Device'], ['label' => 'UID'], ['label' => 'Tipe'], ['label' => 'Status'], ['label' => 'Terdaftar'], ['label' => 'Aksi']]">
        @forelse ($devices as $device)
            <tr>
                <td class="px-4 py-2">{{ $device->employee?->name }}</td>
                <td class="px-4 py-2">{{ $device->employee?->department?->name }}</td>
                <td class="px-4 py-2">{{ $device->name }}</td>
                <td class="px-4 py-2 text-gray-500">{{ $device->device_uid }}</td>
                <td class="px-4 py-2">
                    <x-badge :color="$device->type === 'primary' ? 'blue' : 'gray'">{{ $device->type }}</x-badge>
                </td>
                <td class="px-4 py-2">
                    <x-badge :color="$device->status === 'active' ? 'green' : 'red'">{{ $device->status }}</x-badge>
                </td>
                <td class="px-4 py-2">{{ $device->registered_at?->format('d M Y') }}</td>
                <td class="px-4 py-2 text-right">
                    @can('devices.update')
                        <x-modal :title="'Reset device ' . $device->employee?->name" trigger="Reset">
                            <p class="text-sm text-gray-600">Hapus binding device ini? Karyawan bisa mendaftarkan device baru saat login berikutnya.</p>
                            <x-slot:actions>
                                <form method="POST" action="{{ route('devices.destroy', $device) }}">
                                    @csrf @method('DELETE')
                                    <button class="rounded-lg bg-red-600 px-3 py-1.5 text-sm text-white">Reset</button>
                                </form>
                            </x-slot:actions>
                        </x-modal>
                    @endcan
                </td>
            </tr>
        @empty
            <tr><td colspan="8" class="px-4 py-6 text-center text-gray-400">Belum ada device.</td></tr>
        @endforelse
    </x-table>
</div>

<div class="mt-4">{{ $devices->links() }}</div>
@endsection
