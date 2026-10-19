@extends('layouts.admin')

@section('title', 'Perlu Review')

@section('content')
<form method="GET" class="mb-4 flex items-end gap-3">
    <div>
        <label class="mb-1 block text-sm font-medium">Status</label>
        <select name="status" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @foreach (['pending' => 'Belum diputuskan', 'valid' => 'Valid', 'invalid' => 'Tidak valid', 'all' => 'Semua'] as $value => $label)
                <option value="{{ $value }}" @selected($status === $value)>{{ $label }}</option>
            @endforeach
        </select>
    </div>
    <button class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white">Filter</button>
</form>

<div class="space-y-4">
    @forelse ($attendances as $attendance)
        <div class="rounded-xl border bg-white p-4">
            <div class="flex flex-wrap items-center justify-between gap-2">
                <div>
                    <span class="font-semibold">{{ $attendance->employee?->name }}</span>
                    <span class="text-sm text-gray-500">· {{ $attendance->date->format('d M Y') }}</span>
                    <x-badge :color="$attendance->time_trust === 'suspect' ? 'red' : 'green'">{{ $attendance->time_trust }}</x-badge>
                    @if ($attendance->review_status)
                        <x-badge :color="$attendance->review_status === 'valid' ? 'green' : 'red'">{{ $attendance->review_status }}</x-badge>
                    @else
                        <x-badge color="yellow">belum diputuskan</x-badge>
                    @endif
                </div>
                <div class="text-sm text-gray-600">
                    skor lokal: {{ $attendance->face_score_local ?? '-' }} · server: {{ $attendance->face_score_server ?? '-' }}
                </div>
            </div>

            <div class="mt-3 flex flex-wrap gap-3">
                @foreach ($attendance->faceCaptures as $capture)
                    <div class="text-xs text-gray-500">
                        <div class="mb-1">{{ $capture->type }}</div>
                        @if ($capture->expires_at->isFuture())
                            <a href="{{ route('review.photo', $capture) }}" target="_blank">
                                <img src="{{ route('review.photo', $capture) }}" alt="crop {{ $capture->type }}" class="h-24 w-24 rounded border object-cover">
                            </a>
                        @else
                            <span class="italic">foto kedaluwarsa</span>
                        @endif
                    </div>
                @endforeach
            </div>

            @if (!$attendance->review_status)
                @can('review.update')
                    <form method="POST" action="{{ route('review.mark', $attendance) }}" class="mt-3 flex flex-wrap items-end gap-2">
                        @csrf
                        <div>
                            <label class="mb-1 block text-xs text-gray-500">Catatan (opsional)</label>
                            <input type="text" name="review_note" class="rounded-lg border border-gray-300 px-2 py-1 text-sm">
                        </div>
                        <button name="review_status" value="valid" class="rounded-lg bg-green-600 px-3 py-1.5 text-sm text-white">Valid</button>
                        <button name="review_status" value="invalid" class="rounded-lg bg-red-600 px-3 py-1.5 text-sm text-white">Tidak Valid</button>
                    </form>
                @endcan
            @endif
        </div>
    @empty
        <div class="rounded-xl border bg-white p-6 text-center text-gray-400">Tidak ada data review.</div>
    @endforelse
</div>

<div class="mt-4">{{ $attendances->links() }}</div>
@endsection
