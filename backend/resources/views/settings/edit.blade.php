@extends('layouts.admin')

@section('title', 'Pengaturan')

@section('content')
<form method="POST" action="{{ route('settings.update') }}" class="max-w-md rounded-xl border bg-white p-6">
    @csrf
    <x-form-field name="max_backdated_days" label="Batas Hari Pengajuan Mundur (izin/sakit)" type="number"
        :value="$settings['max_backdated_days']" />
    <button type="submit" class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Simpan</button>
</form>
@endsection
