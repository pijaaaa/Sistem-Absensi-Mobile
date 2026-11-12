@extends('layouts.admin')

@section('title', 'Pengajuan Manager')

@section('content')
<div class="mb-7">
    <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Approval management</p>
    <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Pengajuan Manager</h2>
    <p class="mt-1 text-sm text-gray-500">Tinjau dan kelola pengajuan dari setiap department.</p>
</div>

<form method="GET" data-auto-filter class="mb-5 flex flex-wrap items-end gap-3 rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Status Pengajuan</label>
        <select name="status" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @foreach (['pending' => 'Menunggu', 'approved' => 'Disetujui', 'rejected' => 'Ditolak', 'all' => 'Semua'] as $value => $label)
                <option value="{{ $value }}" @selected($status === $value)>{{ $label }}</option>
            @endforeach
        </select>
    </div>
</form>

<div class="overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <x-table :headers="[['label' => 'Aksi'], ['label' => 'Manager'], ['label' => 'Department'], ['label' => 'Jenis'], ['label' => 'Tanggal'], ['label' => 'Alasan'], ['label' => 'Status']]">
        @forelse ($requests as $request)
            <tr>
                <td class="px-4 py-2">
                    @if ($request->status === 'pending')
                        @can('leave_requests.approve')
                            <div class="flex flex-wrap gap-2">
                                <form method="POST" action="{{ route('leave-requests.approve', $request) }}">@csrf<button class="rounded-lg bg-primary px-3 py-1.5 text-sm font-semibold text-white hover:bg-primary/90">Setujui</button></form>
                                <x-modal :title="'Tolak pengajuan ' . $request->employee?->name" trigger="Tolak"><form method="POST" action="{{ route('leave-requests.reject', $request) }}">@csrf<label class="mb-1 block text-sm font-medium">Alasan penolakan</label><textarea name="rejection_reason" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm" required></textarea><x-slot:actions><button class="rounded-lg bg-red-600 px-3 py-1.5 text-sm font-semibold text-white">Tolak</button></x-slot:actions></form></x-modal>
                            </div>
                        @endcan
                    @endif
                </td>
                <td class="px-4 py-2 font-bold text-neutral-dark">{{ $request->employee?->name }}</td>
                <td class="px-4 py-2">{{ $request->employee?->department?->name }}</td>
                <td class="px-4 py-2"><span class="rounded-md bg-[#edf4ef] px-2 py-1 text-xs font-semibold text-primary">{{ $request->type }}</span></td>
                <td class="px-4 py-2">{{ $request->start_date->format('d M') }} – {{ $request->end_date->format('d M Y') }}</td>
                <td class="px-4 py-2 text-gray-500">{{ $request->reason }}</td>
                <td class="px-4 py-2">
                    <x-badge :color="['pending' => 'yellow', 'approved' => 'green', 'rejected' => 'red'][$request->status]">{{ $request->status }}</x-badge>
                </td>
            </tr>
        @empty
            <tr><td colspan="7" class="px-4 py-6 text-center text-gray-400">Tidak ada pengajuan.</td></tr>
        @endforelse
    </x-table>
</div>
@endsection
