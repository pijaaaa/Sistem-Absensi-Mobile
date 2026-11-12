@props(['headers'])

<table class="w-full text-sm">
    <thead class="bg-[#f7faf8]">
        <tr class="border-b border-[#e5eee8] text-left text-[10px] font-bold uppercase tracking-[0.12em] text-primary/50">
            @foreach ($headers as $h)
                <th class="whitespace-nowrap px-5 py-3.5">{{ $h['label'] }}</th>
            @endforeach
        </tr>
    </thead>
    <tbody class="divide-y divide-[#edf2ee] [&_tr:hover]:bg-[#f8fbf9] [&_td]:px-5 [&_td]:py-3.5">
        {{ $slot }}
    </tbody>
</table>
