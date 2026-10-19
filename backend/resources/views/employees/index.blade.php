@extends('layouts.admin')

@section('title', 'Karyawan')

@section('content')
<div class="mb-4 flex items-center justify-between">
    <h2 class="text-lg font-semibold">Daftar Karyawan</h2>
    @can('employees.create')
        <a href="{{ route('employees.create') }}"
            class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Tambah</a>
    @endcan
</div>

<div class="overflow-x-auto rounded-xl border bg-white">
    <x-table :headers="[['label' => 'Nama'], ['label' => 'NIP'], ['label' => 'Department'], ['label' => 'Lokasi'], ['label' => 'Role'], ['label' => 'Status'], ['label' => 'Aksi']]">
        @forelse ($employees as $employee)
            <tr>
                <td class="px-4 py-2">{{ $employee->name }}</td>
                <td class="px-4 py-2">{{ $employee->nip }}</td>
                <td class="px-4 py-2">{{ $employee->department?->name }}</td>
                <td class="px-4 py-2">{{ $employee->workLocation?->name }}</td>
                <td class="px-4 py-2">{{ $employee->user?->role?->label() }}</td>
                <td class="px-4 py-2">
                    <x-badge :color="$employee->is_active ? 'green' : 'gray'">{{ $employee->is_active ? 'Aktif' : 'Nonaktif' }}</x-badge>
                </td>
                <td class="px-4 py-2 text-right">
                    @can('employees.update')
                        <a href="{{ route('employees.edit', $employee) }}" class="text-sm text-blue-600 hover:underline">Ubah</a>
                    @endcan
                    @can('employees.delete')
                        <x-modal :title="'Hapus ' . $employee->name" trigger="Hapus">
                            <p class="text-sm text-gray-600">Yakin hapus karyawan ini? Akun login ikut terhapus.</p>
                            <x-slot:actions>
                                <form method="POST" action="{{ route('employees.destroy', $employee) }}">
                                    @csrf @method('DELETE')
                                    <button class="rounded-lg bg-red-600 px-3 py-1.5 text-sm text-white">Hapus</button>
                                </form>
                            </x-slot:actions>
                        </x-modal>
                    @endcan
                </td>
            </tr>
        @empty
            <tr><td colspan="7" class="px-4 py-6 text-center text-gray-400">Belum ada data.</td></tr>
        @endforelse
    </x-table>
</div>

<div class="mt-4">{{ $employees->links() }}</div>
@endsection
