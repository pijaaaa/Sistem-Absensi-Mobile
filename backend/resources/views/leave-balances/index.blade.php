@extends('layouts.admin')

@section('title', 'Jatah Cuti')

@section('content')
<div class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
    <div>
        <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Leave management</p>
        <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Jatah Cuti</h2>
        <p class="mt-1 text-sm text-gray-500">Kelola kuota cuti tahunan setiap karyawan.</p>
    </div>
</div>

<form method="POST" action="{{ route('leave-quota.update') }}" class="rounded-xl border border-[#dce7e0] bg-white p-5 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    @csrf
    <input type="hidden" name="year" value="{{ $year }}">

    <div class="mb-5 flex flex-wrap items-end gap-4 rounded-lg bg-[#f7faf8] p-4">
        <div>
            <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Tahun</label>
            <input type="number" value="{{ $year }}" class="w-28 rounded-lg border border-gray-300 px-3 py-2 text-sm" disabled>
        </div>
        <div>
            <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Jatah Default / Tahun</label>
            <input type="number" name="default_quota" value="{{ old('default_quota', $defaultQuota) }}" class="w-32 rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('default_quota') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
    </div>

    <div class="overflow-x-auto">
        <x-table :headers="[['label' => 'Karyawan'], ['label' => 'Department'], ['label' => 'Terpakai'], ['label' => 'Jatah']]">
            @foreach ($employees as $employee)
                @php($balance = $balances->get($employee->id))
                <tr>
                    <td class="px-4 py-2 font-bold text-neutral-dark">{{ $employee->name }}</td>
                    <td class="px-4 py-2">{{ $employee->department?->name }}</td>
                    <td class="px-4 py-2 font-semibold text-[#b42318]">{{ $balance?->used ?? 0 }} hari</td>
                    <td class="px-4 py-2">
                        <input type="number" name="quotas[{{ $employee->id }}]"
                            value="{{ old('quotas.'.$employee->id, $balance?->quota ?? $defaultQuota) }}"
                            class="w-24 rounded-lg border border-[#cddbd2] px-2.5 py-1.5 text-sm font-semibold focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/10">
                    </td>
                </tr>
            @endforeach
        </x-table>
    </div>

    <button type="submit" class="mt-5 rounded-lg bg-secondary px-5 py-2.5 text-sm font-bold text-neutral-dark shadow-sm hover:bg-amber-400">Simpan Perubahan</button>
</form>
@endsection
