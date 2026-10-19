@extends('layouts.admin')

@section('title', 'Pengajuan Manager')

@section('content')
<form method="GET" class="mb-4 flex items-end gap-3">
    <div>
        <label class="mb-1 block text-sm font-medium">Status</label>
        <select name="status" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @foreach (['pending' => 'Menunggu', 'approved' => 'Disetujui', 'rejected' => 'Ditolak', 'all' => 'Semua'] as $value => $label)
                <option value="{{ $value }}" @selected($status === $value)>{{ $label }}</option>
            @endforeach
        </select>
    </div>
    <button class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white">Filter</button>
</form>

<div class="overflow-x-auto rounded-xl border bg-white">
    <x-table :headers="[['label' => 'Manager'], ['label' => 'Department'], ['label' => 'Jenis'], ['label' => 'Tanggal'], ['label' => 'Alasan'], ['label' => 'Status'], ['label' => 'Aksi']]">
        @forelse ($requests as $request)
            <tr>
                <td class="px-4 py-2">{{ $request->employee?->name }}</td>
                <td class="px-4 py-2">{{ $request->employee?->department?->name }}</td>
                <td class="px-4 py-2">{{ $request->type }}</td>
                <td class="px-4 py-2">{{ $request->start_date->format('d M') }} – {{ $request->end_date->format('d M Y') }}</td>
                <td class="px-4 py-2 text-gray-500">{{ $request->reason }}</td>
                <td class="px-4 py-2">
                    <x-badge :color="['pending' => 'yellow', 'approved' => 'green', 'rejected' => 'red'][$request->status]">{{ $request->status }}</x-badge>
                </td>
                <td class="px-4 py-2 text-right">
                    @if ($request->status === 'pending')
                        @can('leave_requests.approve')
                            <form method="POST" action="{{ route('leave-requests.approve', $request) }}" class="inline">
                                @csrf
                                <button class="text-sm text-green-600 hover:underline">Setujui</button>
                            </form>
                            <x-modal :title="'Tolak pengajuan ' . $request->employee?->name" trigger="Tolak">
                                <form method="POST" action="{{ route('leave-requests.reject', $request) }}">
                                    @csrf
                                    <label class="mb-1 block text-sm font-medium">Alasan penolakan</label>
                                    <textarea name="rejection_reason" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm" required></textarea>
                                    <x-slot:actions>
                                        <button class="rounded-lg bg-red-600 px-3 py-1.5 text-sm text-white">Tolak</button>
                                    </x-slot:actions>
                                </form>
                            </x-modal>
                        @endcan
                    @endif
                </td>
            </tr>
        @empty
            <tr><td colspan="7" class="px-4 py-6 text-center text-gray-400">Tidak ada pengajuan.</td></tr>
        @endforelse
    </x-table>
</div>
@endsection
