@extends('layouts.admin')

@section('title', 'Perlu Review')

@section('content')
<div class="mb-7">
    <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">Attendance verification</p>
    <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Perlu Review</h2>
    <p class="mt-1 text-sm text-gray-500">Periksa data absensi yang memerlukan validasi manual.</p>
</div>

<form method="GET" data-auto-filter class="mb-5 flex flex-wrap items-end gap-3 rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Status Review</label>
        <select name="status" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @foreach (['pending' => 'Belum diputuskan', 'valid' => 'Valid', 'invalid' => 'Tidak valid', 'all' => 'Semua'] as $value => $label)
                <option value="{{ $value }}" @selected($status === $value)>{{ $label }}</option>
            @endforeach
        </select>
    </div>
</form>

<div class="grid gap-4 xl:grid-cols-2">
    @forelse ($attendances as $attendance)
        <div class="rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
            <div class="flex flex-wrap items-center justify-between gap-2">
                <div>
                    <span class="font-extrabold text-neutral-dark">{{ $attendance->employee?->name }}</span>
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
                                <img src="{{ route('review.photo', $capture) }}" alt="crop {{ $capture->type }}" class="h-20 w-20 rounded-lg border border-[#dce7e0] object-cover shadow-sm">
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
                        <button name="review_status" value="valid" class="rounded-lg bg-primary px-3 py-1.5 text-sm font-semibold text-white hover:bg-tertiary">Valid</button>
                        <button name="review_status" value="invalid" class="rounded-lg bg-[#fde8e7] px-3 py-1.5 text-sm font-semibold text-[#b42318] hover:bg-red-100">Tidak Valid</button>
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
