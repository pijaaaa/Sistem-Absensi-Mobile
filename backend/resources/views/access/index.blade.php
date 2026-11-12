@extends('layouts.admin')

@section('title', 'Manajemen Akses')

@section('content')
<form method="POST" action="{{ route('access.index') }}" x-data>
    @csrf
    <div class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
            <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Administration</p>
            <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Manajemen Akses</h2>
            <p class="mt-1 text-sm text-gray-500">Atur izin pengguna berdasarkan modul dan aksi.</p>
        </div>
        <button type="submit" class="rounded-lg bg-secondary px-5 py-2.5 text-sm font-bold text-neutral-dark shadow-sm hover:bg-amber-400">Simpan Perubahan</button>
    </div>
    <div class="mb-5 rounded-xl border border-[#dce7e0] bg-[#f7faf8] p-4 text-sm text-gray-600">
        Atur izin per modul dan per aksi. Mencentang <strong>Ubah</strong> tidak otomatis mengaktifkan <strong>Hapus</strong>.
        Izin pada modul <em>{{ __('Manajemen Akses') }}</em> dan <em>Manajemen Menu</em> milik superadmin terkunci.
    </div>

    <div class="space-y-4">
        @foreach ($modules as $module)
            <div class="overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]" x-data="{ all: false }">
                <div class="flex items-center justify-between border-b border-[#edf2ee] bg-[#f7faf8] px-5 py-3">
                    <span class="text-sm font-extrabold text-neutral-dark">{{ $module->label }} <span class="font-normal text-gray-400">({{ $module->key }})</span></span>
                    <label class="flex items-center gap-1 text-xs text-gray-500">
                        <input type="checkbox" x-model="all"
                            @change="$el.closest('.rounded-xl').querySelectorAll('input[type=checkbox]:not([disabled]):not([data-master])').forEach(c => c.checked = all)">
                        Centang semua
                    </label>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="border-b border-[#edf2ee] bg-white text-left text-[10px] font-bold uppercase tracking-wide text-primary/60">
                                <th class="px-4 py-2">Aksi</th>
                                @foreach ($roles as $roleValue => $role)
                                    <th class="px-4 py-2">{{ $role['label'] }}</th>
                                @endforeach
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($module->actionList() as $action)
                                @php($key = $module->key.'.'.$action->value)
                                <tr class="border-b border-[#edf2ee] last:border-0 hover:bg-[#f8fbf9]">
                                    <td class="px-4 py-2">{{ $action->label() }} <span class="text-gray-400">({{ $key }})</span></td>
                                    @foreach ($roles as $roleValue => $role)
                                        @php($checked = $role['granted']->contains($key))
                                        @php($locked = app(\App\Support\Access\PermissionService::class)->isLocked($roleValue, $key))
                                        <td class="px-4 py-2">
                                            <input type="checkbox" name="matrix[{{ $roleValue }}][{{ $key }}]" value="1"
                                                data-master
                                                {{ $checked ? 'checked' : '' }}
                                                {{ $locked ? 'disabled' : '' }}>
                                            @if ($locked)
                                                <input type="hidden" name="matrix[{{ $roleValue }}][{{ $key }}]" value="1">
                                            @endif
                                        </td>
                                    @endforeach
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        @endforeach
    </div>

    <div class="mt-4">
        <button type="submit" class="rounded-lg bg-secondary px-5 py-2.5 text-sm font-bold text-neutral-dark shadow-sm hover:bg-amber-400">
            Simpan Perubahan
        </button>
    </div>
</form>
@endsection
