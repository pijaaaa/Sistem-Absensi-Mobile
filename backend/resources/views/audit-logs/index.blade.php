@extends('layouts.admin')

@section('title', 'Audit Log')

@section('content')
<form method="GET" class="mb-4 flex flex-wrap items-end gap-3 rounded-xl border bg-white p-4">
    <div>
        <label class="mb-1 block text-sm font-medium">Aktor</label>
        <select name="actor_id" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <option value="">Semua</option>
            @foreach ($actors as $actor)
                <option value="{{ $actor->id }}" @selected(request('actor_id') == $actor->id)>{{ $actor->name }}</option>
            @endforeach
        </select>
    </div>
    <div>
        <label class="mb-1 block text-sm font-medium">Aksi</label>
        <input type="text" name="action" value="{{ request('action') }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <div>
        <label class="mb-1 block text-sm font-medium">Dari</label>
        <input type="date" name="from" value="{{ request('from') }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <div>
        <label class="mb-1 block text-sm font-medium">Sampai</label>
        <input type="date" name="to" value="{{ request('to') }}" class="rounded-lg border border-gray-300 px-3 py-2 text-sm">
    </div>
    <button class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Filter</button>
</form>

<div class="overflow-x-auto rounded-xl border bg-white">
    <x-table :headers="[['label' => 'Waktu'], ['label' => 'Aktor'], ['label' => 'Aksi'], ['label' => 'Entitas']]">
        @forelse ($logs as $log)
            <tr>
                <td class="px-4 py-2">{{ $log->created_at->format('d M Y H:i') }}</td>
                <td class="px-4 py-2">{{ $log->actor?->name ?? 'Sistem' }}</td>
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
