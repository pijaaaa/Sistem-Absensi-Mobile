@props(['color' => 'gray', 'label' => null])

@php($colors = [
    'green' => 'bg-[#e4f3e9] text-primary',
    'yellow' => 'bg-[#fff3d6] text-[#9a5b00]',
    'red' => 'bg-[#fde8e7] text-[#b42318]',
    'gray' => 'bg-[#eef2ef] text-[#52645a]',
    'blue' => 'bg-[#e4f0f5] text-[#23627a]',
])
@php($cls = $colors[$color] ?? $colors['gray'])
<span class="inline-flex items-center rounded-full px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide {{ $cls }}">
    {{ $label ?? $slot }}
</span>