@extends('layouts.admin')

@section('title', $department->exists ? 'Ubah Department' : 'Tambah Department')

@section('content')
<form method="POST"
    action="{{ $department->exists ? route('departments.update', $department) : route('departments.store') }}"
    class="max-w-md rounded-xl border bg-white p-6">
    @csrf
    @if ($department->exists) @method('PUT') @endif

    <x-form-field name="name" label="Nama Department" :value="$department->name" />

    <div class="flex gap-2">
        <button type="submit" class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Simpan</button>
        <a href="{{ route('departments.index') }}" class="rounded-lg border px-4 py-2 text-sm">Batal</a>
    </div>
</form>
@endsection
