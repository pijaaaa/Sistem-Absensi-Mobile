@extends('layouts.admin')

@section('title', 'Department')

@section('content')
<div class="mb-4 flex items-center justify-between">
    <h2 class="text-lg font-semibold">Daftar Department</h2>
    @can('departments.create')
        <a href="{{ route('departments.create') }}"
            class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Tambah</a>
    @endcan
</div>

<div class="overflow-x-auto rounded-xl border bg-white">
    <x-table :headers="[['label' => 'Nama'], ['label' => 'Jumlah Karyawan'], ['label' => 'Aksi']]">
        @forelse ($departments as $department)
            <tr>
                <td class="px-4 py-2">{{ $department->name }}</td>
                <td class="px-4 py-2">{{ $department->employees_count }}</td>
                <td class="px-4 py-2 text-right">
                    @can('departments.update')
                        <a href="{{ route('departments.edit', $department) }}" class="text-sm text-blue-600 hover:underline">Ubah</a>
                    @endcan
                    @can('departments.delete')
                        <x-modal :title="'Hapus ' . $department->name" trigger="Hapus">
                            <p class="text-sm text-gray-600">Yakin hapus department ini?</p>
                            <x-slot:actions>
                                <form method="POST" action="{{ route('departments.destroy', $department) }}">
                                    @csrf @method('DELETE')
                                    <button class="rounded-lg bg-red-600 px-3 py-1.5 text-sm text-white">Hapus</button>
                                </form>
                            </x-slot:actions>
                        </x-modal>
                    @endcan
                </td>
            </tr>
        @empty
            <tr><td colspan="3" class="px-4 py-6 text-center text-gray-400">Belum ada data.</td></tr>
        @endforelse
    </x-table>
</div>
@endsection
