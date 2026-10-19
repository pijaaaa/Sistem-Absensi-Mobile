@extends('layouts.admin')

@section('title', 'Manajemen Akses')

@section('content')
<form method="POST" action="{{ route('access.index') }}" x-data>
    @csrf
    <div class="mb-4 flex items-center justify-between">
        <p class="text-sm text-gray-600">
            Atur izin per modul dan per aksi. Mencentang <strong>Ubah</strong> tidak otomatis mengaktifkan <strong>Hapus</strong>.
            Izin pada modul <em>{{ __('Manajemen Akses') }}</em> dan <em>Manajemen Menu</em> milik superadmin terkunci.
        </p>
        <button type="submit" class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">
            Simpan
        </button>
    </div>

    <div class="space-y-4">
        @foreach ($modules as $module)
            <div class="overflow-hidden rounded-xl border bg-white" x-data="{ all: false }">
                <div class="flex items-center justify-between border-b bg-gray-50 px-4 py-2">
                    <span class="text-sm font-semibold">{{ $module->label }} <span class="font-normal text-gray-400">({{ $module->key }})</span></span>
                    <label class="flex items-center gap-1 text-xs text-gray-500">
                        <input type="checkbox" x-model="all"
                            @change="$el.closest('.rounded-xl').querySelectorAll('input[type=checkbox]:not([disabled]):not([data-master])').forEach(c => c.checked = all)">
                        Centang semua
                    </label>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="border-b text-left text-xs uppercase text-gray-400">
                                <th class="px-4 py-2">Aksi</th>
                                @foreach ($roles as $roleValue => $role)
                                    <th class="px-4 py-2">{{ $role['label'] }}</th>
                                @endforeach
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($module->actionList() as $action)
                                @php($key = $module->key.'.'.$action->value)
                                <tr class="border-b last:border-0">
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
        <button type="submit" class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">
            Simpan
        </button>
    </div>
</form>
@endsection
