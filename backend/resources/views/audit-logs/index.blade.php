@extends('layouts.admin')

@section('title', 'Audit Log')

@section('content')
<div class="mb-7">
    <p class="mb-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary/50">System activity</p>
    <h2 class="text-2xl font-extrabold tracking-tight text-neutral-dark">Audit Log</h2>
    <p class="mt-1 text-sm text-gray-500">Pantau seluruh aktivitas perubahan di dalam sistem.</p>
</div>

<form method="GET" data-auto-filter class="mb-5 flex flex-wrap items-end gap-3 rounded-xl border border-[#dce7e0] bg-white p-4 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Aktor</label>
        <select name="actor_id" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <option value="">Semua</option>
            @foreach ($actors as $actor)
                <option value="{{ $actor->id }}" @selected(request('actor_id') == $actor->id)>{{ $actor->name }}</option>
            @endforeach
        </select>
    </div>
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Aksi</label>
        <input type="text" name="action" value="{{ request('action') }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Dari</label>
        <input type="date" name="from" value="{{ request('from') }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <div>
        <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-primary/60">Sampai</label>
        <input type="date" name="to" value="{{ request('to') }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
</form>

<div class="overflow-hidden rounded-xl border border-[#dce7e0] bg-white shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <x-table :headers="[['label' => 'Waktu'], ['label' => 'Aktor'], ['label' => 'Aksi'], ['label' => 'Entitas']]">
        @forelse ($logs as $log)
            <tr>
                <td class="px-4 py-2">{{ $log->created_at->format('d M Y H:i') }}</td>
                <td class="px-4 py-2 font-semibold text-neutral-dark">{{ $log->actor?->name ?? 'Sistem' }}</td>
                <td class="px-4 py-2"><x-badge color="blue">{{ $log->action }}</x-badge></td>
                <td class="px-4 py-2 text-gray-500">{{ class_basename($log->entity_type ?? '') }} #{{ $log->entity_id }}</td>
            </tr>
        @empty
            <tr><td colspan="4" class="px-4 py-6 text-center text-gray-400">Belum ada log.</td></tr>
        @endforelse
    </x-table>
</div>

<div class="mt-4">{{ $logs->links() }}</div>
@endsection
