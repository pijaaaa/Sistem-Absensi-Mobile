@extends('layouts.admin')

@section('title', 'Keterlambatan')

@section('content')
<form method="POST" action="{{ route('lateness.update') }}" class="max-w-3xl rounded-xl border bg-white p-6">
    @csrf
    <p class="mb-4 text-sm text-gray-600">Rentang menit keterlambatan dan warnanya. Kosongkan "Sampai" untuk rentang terakhir (tak terbatas).</p>

    <x-table :headers="[['label' => 'Label'], ['label' => 'Dari (menit)'], ['label' => 'Sampai (menit)'], ['label' => 'Warna'], ['label' => 'Hitung Telat']]">
        @foreach ($rules as $rule)
            <tr>
                <td class="px-4 py-2"><input name="rules[{{ $rule->id }}][label]" value="{{ $rule->label }}" class="w-full rounded border border-gray-300 px-2 py-1"></td>
                <td class="px-4 py-2"><input type="number" name="rules[{{ $rule->id }}][from_minute]" value="{{ $rule->from_minute }}" class="w-24 rounded border border-gray-300 px-2 py-1"></td>
                <td class="px-4 py-2"><input type="number" name="rules[{{ $rule->id }}][to_minute]" value="{{ $rule->to_minute }}" class="w-24 rounded border border-gray-300 px-2 py-1"></td>
                <td class="px-4 py-2">
                    <select name="rules[{{ $rule->id }}][color]" class="rounded border border-gray-300 px-2 py-1">
                        @foreach (['green', 'yellow', 'red', 'gray'] as $color)
                            <option value="{{ $color }}" @selected($rule->color === $color)>{{ $color }}</option>
                        @endforeach
                    </select>
                </td>
                <td class="px-4 py-2"><input type="checkbox" name="rules[{{ $rule->id }}][is_counted_late]" value="1" @checked($rule->is_counted_late)></td>
            </tr>
        @endforeach
    </x-table>

    <button type="submit" class="mt-4 rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Simpan</button>
</form>
@endsection
