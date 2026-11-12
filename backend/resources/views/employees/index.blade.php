@extends('layouts.admin')

@section('title', 'Karyawan')

@section('content')
<div class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
    <div>
        <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Data management</p>
        <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Karyawan</h2>
        <p class="mt-1 text-sm text-gray-500">Kelola data, role, dan status karyawan.</p>
    </div>
    @can('employees.create')
        <a href="{{ route('employees.create') }}" class="inline-flex items-center justify-center rounded-lg bg-secondary px-4 py-2.5 text-sm font-bold text-neutral-dark shadow-sm hover:bg-amber-400">+ Tambah Karyawan</a>
    @endcan
</div>

<div class="overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <x-table :headers="[['label' => 'Aksi'], ['label' => 'Nama'], ['label' => 'NIP'], ['label' => 'Department'], ['label' => 'Lokasi'], ['label' => 'Role'], ['label' => 'Status']]">
        @forelse ($employees as $employee)
            <tr>
                <td class="px-4 py-2">
                    <div class="flex flex-wrap gap-2">
                        @can('employees.update')
                            <a href="{{ route('employees.edit', $employee) }}" class="inline-flex rounded-lg bg-primary px-3 py-1.5 text-sm font-semibold text-white hover:bg-primary/90">Ubah</a>
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
                    </div>
                </td>
                <td class="px-4 py-2 font-bold text-neutral-dark">{{ $employee->name }}</td>
                <td class="px-4 py-2 text-gray-500">{{ $employee->nip }}</td>
                <td class="px-4 py-2">{{ $employee->department?->name }}</td>
                <td class="px-4 py-2">{{ $employee->workLocation?->name }}</td>
                <td class="px-4 py-2">{{ $employee->user?->role?->label() }}</td>
                <td class="px-4 py-2">
                    <x-badge :color="$employee->is_active ? 'green' : 'gray'">{{ $employee->is_active ? 'Aktif' : 'Nonaktif' }}</x-badge>
                </td>
            </tr>
        @empty
            <tr><td colspan="7" class="px-4 py-6 text-center text-gray-400">Belum ada data.</td></tr>
        @endforelse
    </x-table>
</div>

<div class="mt-4">{{ $employees->links() }}</div>
@endsection
