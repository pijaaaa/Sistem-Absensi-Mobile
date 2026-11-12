@props(['title' => 'Konfirmasi', 'trigger' => 'Buka'])

<div x-data="{ open: false }" class="inline">
    <button type="button" @click="open = true"
        class="rounded-lg px-2.5 py-1.5 text-xs font-semibold text-red-600 transition hover:bg-red-50">
        {{ $trigger }}
    </button>

    <template x-if="open">
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-dark/50 p-4 backdrop-blur-sm">
            <div class="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl shadow-neutral-dark/20" @click.away="open = false">
                <h3 class="mb-3 text-base font-semibold">{{ $title }}</h3>
                {{ $slot }}
                <div class="mt-4 flex justify-end gap-2">
                    <button type="button" @click="open = false"
                        class="rounded-xl border border-[#d5e1d9] px-3 py-2 text-sm font-semibold text-primary hover:bg-[#f4f8f5]">Batal</button>
                    {{ $actions ?? '' }}
                </div>
            </div>
        </div>
    </template>
</div>
