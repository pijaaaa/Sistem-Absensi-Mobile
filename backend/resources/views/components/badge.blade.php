@props(['color' => 'gray', 'label' => null])

@php($colors = [
    'green' => 'bg-green-100 text-green-800',
    'yellow' => 'bg-yellow-100 text-yellow-800',
    'red' => 'bg-red-100 text-red-800',
    'gray' => 'bg-gray-100 text-gray-600',
    'blue' => 'bg-blue-100 text-blue-800',
])
@php($cls = $colors[$color] ?? $colors['gray'])
<span class="inline-flex items-center rounded px-2.5 py-0.5 text-xs font-medium {{ $cls }}">
    {{ $label ?? $slot }}
</span>