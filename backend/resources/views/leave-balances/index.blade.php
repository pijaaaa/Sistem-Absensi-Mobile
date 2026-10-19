@extends('layouts.admin')

@section('title', 'Jatah Cuti')

@section('content')
<form method="POST" action="{{ route('leave-quota.update') }}" class="rounded-xl border bg-white p-6">
    @csrf
    <input type="hidden" name="year" value="{{ $year }}">

    <div class="mb-4 flex flex-wrap items-end gap-3">
        <div>
            <label class="mb-1 block text-sm font-medium">Tahun</label>
            <input type="number" value="{{ $year }}" class="w-28 rounded-lg border border-gray-300 px-3 py-2 text-sm" disabled>
        </div>
        <div>
            <label class="mb-1 block text-sm font-medium">Jatah Default / Tahun</label>
            <input type="number" name="default_quota" value="{{ old('default_quota', $defaultQuota) }}" class="w-32 rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('default_quota') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
    </div>

    <div class="overflow-x-auto">
        <x-table :headers="[['label' => 'Karyawan'], ['label' => 'Department'], ['label' => 'Terpakai'], ['label' => 'Jatah']]">
            @foreach ($employees as $employee)
                @php($balance = $balances->get($employee->id))
                <tr>
                    <td class="px-4 py-2">{{ $employee->name }}</td>
                    <td class="px-4 py-2">{{ $employee->department?->name }}</td>
                    <td class="px-4 py-2">{{ $balance?->used ?? 0 }}</td>
                    <td class="px-4 py-2">
                        <input type="number" name="quotas[{{ $employee->id }}]"
                            value="{{ old('quotas.'.$employee->id, $balance?->quota ?? $defaultQuota) }}"
                            class="w-24 rounded border border-gray-300 px-2 py-1">
                    </td>
                </tr>
            @endforeach
        </x-table>
    </div>

    <button type="submit" class="mt-4 rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Simpan</button>
</form>
@endsection
