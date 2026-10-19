@props(['headers'])

<table class="w-full text-sm">
    <thead>
        <tr class="border-b text-left text-xs uppercase text-gray-400">
            @foreach ($headers as $h)
                <th class="px-4 py-2">{{ $h['label'] }}</th>
            @endforeach
        </tr>
    </thead>
    <tbody class="divide-y">
        {{ $slot }}
    </tbody>
</table>
