@props(['title' => 'Konfirmasi', 'trigger' => 'Buka'])

<div x-data="{ open: false }" class="inline">
    <button type="button" @click="open = true"
        class="rounded px-2 py-1 text-xs text-red-600 hover:bg-red-50">
        {{ $trigger }}
    </button>

    <template x-if="open">
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
            <div class="w-full max-w-md rounded-xl bg-white p-6 shadow-xl" @click.away="open = false">
                <h3 class="mb-3 text-base font-semibold">{{ $title }}</h3>
                {{ $slot }}
                <div class="mt-4 flex justify-end gap-2">
                    <button type="button" @click="open = false"
                        class="rounded-lg border px-3 py-1.5 text-sm">Batal</button>
                    {{ $actions ?? '' }}
                </div>
            </div>
        </div>
    </template>
</div>
