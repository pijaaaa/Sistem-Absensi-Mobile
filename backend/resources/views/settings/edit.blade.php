@extends('layouts.admin')

@section('title', 'Pengaturan')

@php
    $bool = fn($k) => (bool) $settings[$k];
@endphp

@section('content')
<form method="POST" action="{{ route('settings.update') }}" class="max-w-2xl rounded-xl border bg-white p-6">
    @csrf
    <x-form-field name="max_backdated_days" label="Batas Hari Pengajuan Mundur (izin/sakit)" type="number"
        :value="$settings['max_backdated_days']" />

    <fieldset class="mt-6 border-t pt-4">
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

    <fieldset class="mt-6 border-t pt-4">
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

    <button type="submit" class="mt-6 rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Simpan</button>
</form>
@endsection
