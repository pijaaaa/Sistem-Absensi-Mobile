@extends('layouts.admin')

@section('title', 'Jadwal Kerja')

@section('content')
@php($days = [1 => 'Senin', 2 => 'Selasa', 3 => 'Rabu', 4 => 'Kamis', 5 => 'Jumat', 6 => 'Sabtu', 0 => 'Minggu'])
<form method="POST" action="{{ route('schedule.update') }}" class="max-w-xl rounded-xl border bg-white p-6">
    @csrf

    <div class="mb-4">
        <label class="mb-2 block text-sm font-medium">Hari Kerja</label>
        <div class="flex flex-wrap gap-3">
            @foreach ($days as $value => $label)
                <label class="flex items-center gap-1 text-sm">
                    <input type="checkbox" name="work_days[]" value="{{ $value }}"
                        @checked(in_array($value, old('work_days', $schedule->work_days ?? []), false))>
                    {{ $label }}
                </label>
            @endforeach
        </div>
        @error('work_days') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
    </div>

    <x-form-field name="start_time" label="Jam Masuk" type="time" :value="substr((string) $schedule->start_time, 0, 5)" />
    <x-form-field name="end_time" label="Jam Pulang" type="time" :value="substr((string) $schedule->end_time, 0, 5)" />
    <x-form-field name="timezone" label="Timezone" :value="$schedule->timezone" />

    <button type="submit" class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Simpan</button>
</form>
@endsection
