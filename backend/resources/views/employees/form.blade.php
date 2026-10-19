@extends('layouts.admin')

@section('title', $employee->exists ? 'Ubah Karyawan' : 'Tambah Karyawan')

@section('content')
<form method="POST"
    action="{{ $employee->exists ? route('employees.update', $employee) : route('employees.store') }}"
    class="max-w-2xl rounded-xl border bg-white p-6">
    @csrf
    @if ($employee->exists) @method('PUT') @endif

    <div class="grid grid-cols-2 gap-4">
        <x-form-field name="name" label="Nama" :value="$employee->name" />
        <x-form-field name="nip" label="NIP" :value="$employee->nip" />
        <x-form-field name="email" label="Email" type="email" :value="$employee->user?->email" />
        <x-form-field name="password" label="{{ $employee->exists ? 'Password (kosongkan bila tak diubah)' : 'Password' }}" type="password" />
        <x-form-field name="password_confirmation" label="Konfirmasi Password" type="password" />
        <div class="mb-4">
            <label class="mb-1 block text-sm font-medium">Role</label>
            <select name="role" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
                <option value="karyawan" @selected(old('role', $employee->user?->role?->value) === 'karyawan')>Karyawan</option>
                <option value="manager_department" @selected(old('role', $employee->user?->role?->value) === 'manager_department')>Manager Department</option>
            </select>
            @error('role') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <div class="mb-4">
            <label class="mb-1 block text-sm font-medium">Department</label>
            <select name="department_id" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
                @foreach ($departments as $department)
                    <option value="{{ $department->id }}" @selected(old('department_id', $employee->department_id) == $department->id)>{{ $department->name }}</option>
                @endforeach
            </select>
            @error('department_id') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <div class="mb-4">
            <label class="mb-1 block text-sm font-medium">Lokasi Kerja</label>
            <select name="work_location_id" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
                @foreach ($locations as $location)
                    <option value="{{ $location->id }}" @selected(old('work_location_id', $employee->work_location_id) == $location->id)>{{ $location->name }}</option>
                @endforeach
            </select>
            @error('work_location_id') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
    </div>

    <label class="mb-4 flex items-center gap-2 text-sm">
        <input type="checkbox" name="is_active" value="1" @checked(old('is_active', $employee->is_active ?? true))>
        Aktif
    </label>

    <div class="flex gap-2">
        <button type="submit" class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Simpan</button>
        <a href="{{ route('employees.index') }}" class="rounded-lg border px-4 py-2 text-sm">Batal</a>
    </div>
</form>
@endsection
