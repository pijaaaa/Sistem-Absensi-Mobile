@extends('layouts.admin')

@section('title', 'Pengaturan')

@php
    $bool = fn($k) => (bool) $settings[$k];
@endphp

@section('content')
<form method="POST" action="{{ route('settings.update') }}" class="max-w-6xl">
    @csrf
    <div class="mb-5 rounded-xl border border-[#dce7e0] bg-white p-5 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
        <x-form-field name="max_backdated_days" label="Batas Hari Pengajuan Mundur (izin/sakit)" type="number"
            :value="$settings['max_backdated_days']" />
    </div>

    <div class="grid items-start gap-5 lg:grid-cols-2">
        <div class="space-y-5">
            <fieldset class="rounded-xl border border-[#dce7e0] bg-white p-5 pt-3 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
        <legend class="px-2 text-sm font-semibold text-gray-700">Jadwal Kerja</legend>
        @php($days = [1 => 'Senin', 2 => 'Selasa', 3 => 'Rabu', 4 => 'Kamis', 5 => 'Jumat', 6 => 'Sabtu', 0 => 'Minggu'])
        <div class="mt-3 flex flex-wrap gap-3">
            @foreach ($days as $value => $label)
                <label class="flex items-center gap-2 text-sm">
                    <input type="checkbox" name="work_days[]" value="{{ $value }}" @checked(in_array($value, old('work_days', $schedule->work_days ?? []), false))>
                    {{ $label }}
                </label>
            @endforeach
        </div>
        <div class="mt-4 grid gap-4 sm:grid-cols-3">
            <x-form-field name="start_time" label="Jam Masuk" type="time" :value="substr((string) $schedule->start_time, 0, 5)" />
            <x-form-field name="end_time" label="Jam Pulang" type="time" :value="substr((string) $schedule->end_time, 0, 5)" />
            <x-form-field name="timezone" label="Timezone" :value="$schedule->timezone" />
        </div>
    </fieldset>

    <fieldset class="mt-6 rounded-xl border border-[#dce7e0] bg-[#fbfdfb] p-4 pt-3">
        <legend class="px-2 text-sm font-semibold text-gray-700">Aturan Keterlambatan</legend>
        <p class="mb-4 text-xs text-gray-500">Tentukan rentang menit dan status keterlambatan.</p>
        <div class="overflow-x-auto rounded-lg border border-[#dce7e0] bg-white">
            <table class="w-full text-xs">
                <thead class="bg-[#f7faf8] text-left font-bold uppercase tracking-wide text-primary/60">
                    <tr><th class="px-3 py-2">Label</th><th class="px-3 py-2">Dari</th><th class="px-3 py-2">Sampai</th><th class="px-3 py-2">Warna</th><th class="px-3 py-2">Hitung</th></tr>
                </thead>
                <tbody class="divide-y divide-[#edf2ee]">
                    @foreach ($latenessRules as $rule)
                        <tr>
                            <td class="px-3 py-2"><input name="rules[{{ $rule->id }}][label]" value="{{ $rule->label }}" class="w-full px-2 py-1 text-xs"></td>
                            <td class="px-3 py-2"><input type="number" name="rules[{{ $rule->id }}][from_minute]" value="{{ $rule->from_minute }}" class="w-20 px-2 py-1 text-xs"></td>
                            <td class="px-3 py-2"><input type="number" name="rules[{{ $rule->id }}][to_minute]" value="{{ $rule->to_minute }}" class="w-20 px-2 py-1 text-xs"></td>
                            <td class="px-3 py-2"><select name="rules[{{ $rule->id }}][color]" class="px-2 py-1 text-xs">@foreach (['green', 'yellow', 'red', 'gray'] as $color)<option value="{{ $color }}" @selected($rule->color === $color)>{{ $color }}</option>@endforeach</select></td>
                            <td class="px-3 py-2 text-center"><input type="checkbox" name="rules[{{ $rule->id }}][is_counted_late]" value="1" @checked($rule->is_counted_late)></td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </fieldset>
        </div>

        <div class="space-y-5">
    <fieldset class="rounded-xl border border-[#dce7e0] bg-white p-5 pt-3 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
        <legend class="px-2 text-sm font-semibold text-gray-700">Pengingat Absensi (mobile push)</legend>

        <label class="mt-3 flex items-center gap-2">
            <input type="checkbox" name="notif_reminder_enabled" value="1" @checked($bool('notif_reminder_enabled'))>
            <span class="text-sm">Aktifkan semua pengingat</span>
        </label>

        <div class="mt-3 grid gap-4 sm:grid-cols-2">
            <x-form-field name="notif_reminder_checkin_offset" label="Offset reminder masuk (menit)" type="number"
                :value="$settings['notif_reminder_checkin_offset']" />
            <x-form-field name="notif_reminder_checkout_offset" label="Offset reminder pulang (menit)" type="number"
                :value="$settings['notif_reminder_checkout_offset']" />
            <x-form-field name="notif_reminder_forgot_checkout_after" label="Jeda lupa pulang (menit)" type="number"
                :value="$settings['notif_reminder_forgot_checkout_after']" />
            <x-form-field name="notif_retention_days" label="Retensi notifikasi (hari)" type="number"
                :value="$settings['notif_retention_days'] ?? 90" />
        </div>

        <label class="mt-3 flex items-center gap-2">
            <input type="checkbox" name="notif_reminder_checkin_enabled" value="1" @checked($bool('notif_reminder_checkin_enabled'))>
            <span class="text-sm">Reminder masuk</span>
        </label>
        <label class="mt-2 flex items-center gap-2">
            <input type="checkbox" name="notif_reminder_checkout_enabled" value="1" @checked($bool('notif_reminder_checkout_enabled'))>
            <span class="text-sm">Reminder pulang</span>
        </label>
        <label class="mt-2 flex items-center gap-2">
            <input type="checkbox" name="notif_reminder_forgot_checkout_enabled" value="1" @checked($bool('notif_reminder_forgot_checkout_enabled'))>
            <span class="text-sm">Pengingat lupa pulang</span>
        </label>
    </fieldset>

    <fieldset class="mt-6 rounded-xl border border-[#dce7e0] bg-white p-4 pt-3">
        <legend class="px-2 text-sm font-semibold text-gray-700">Ringkasan Harian Manager</legend>
        <div class="mt-3 grid gap-4 sm:grid-cols-3">
            <x-form-field name="notif_summary_hour" label="Jam (0-23)" type="number" :value="$settings['notif_summary_hour']" />
            <x-form-field name="notif_summary_minute" label="Menit (0-59)" type="number" :value="$settings['notif_summary_minute']" />
            <label class="flex items-center gap-2 self-end pb-1">
                <input type="checkbox" name="notif_summary_enabled" value="1" @checked($bool('notif_summary_enabled'))>
                <span class="text-sm">Aktifkan</span>
            </label>
        </div>
    </fieldset>
        </div>
    </div>

    <button type="submit" class="mt-6 rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Simpan</button>
</form>
@endsection
