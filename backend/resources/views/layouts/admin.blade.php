@php
    $sidebar = app(\App\Support\Access\MenuService::class)->forRole(auth()->user()->role, 'web');
@endphp
@extends('layouts.app')

@section('body')
<div class="shell-grid flex h-screen overflow-hidden">
    <aside class="hidden h-screen w-64 shrink-0 flex-col bg-primary text-white md:flex">
        <div class="border-b border-white/10 px-7 py-8">
            <span class="text-xl font-extrabold tracking-tight">Absensi<span class="text-secondary">.</span></span>
            <p class="mt-1 text-[10px] font-semibold uppercase tracking-[0.16em] text-white/50">Management system</p>
        </div>
        <nav class="min-h-0 flex-1 space-y-1 overflow-y-auto px-4 py-5">
            @foreach ($sidebar as $menu)
                @continue(in_array($menu->route_or_feature_key, ['schedule.index', 'lateness.index'], true))
                @php($href = \Illuminate\Support\Facades\Route::has($menu->route_or_feature_key) ? route($menu->route_or_feature_key) : ($menu->route_or_feature_key === 'attendance-monitoring.index' ? url('/attendance-monitoring') : '#'))
                <a href="{{ $href }}"
                    class="flex items-center gap-3 rounded-lg px-3 py-2.5 text-[13px] transition {{ request()->routeIs($menu->route_or_feature_key) ? 'bg-secondary font-bold text-neutral-dark shadow-sm' : 'text-white/65 hover:bg-white/10 hover:text-white' }}">
                    <span class="flex h-6 w-6 items-center justify-center rounded-md bg-current/10 text-[10px] uppercase opacity-70">{{ Str::substr($menu->icon ?? '', 0, 2) }}</span>
                    <span>{{ $menu->label }}</span>
                </a>
            @endforeach
        </nav>
    </aside>

    <div class="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden">
        <header class="flex items-center justify-between border-b border-[#dce7e0] bg-white px-6 py-5 lg:px-10">
            <div>
                <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-primary/40">Workspace</p>
                <h1 class="mt-1 text-lg font-extrabold text-neutral-dark">@yield('title', 'Admin')</h1>
            </div>
            <div class="flex items-center gap-4">
                <a href="{{ route('profile.edit') }}" class="rounded-lg px-3 py-2 text-sm font-semibold text-primary hover:bg-[#edf4ef]">Profil</a>
                <span class="hidden text-sm font-medium text-neutral-dark sm:inline">{{ auth()->user()->name }}</span>
                <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button type="submit" class="rounded-lg px-3 py-2 text-sm font-semibold text-primary hover:bg-[#edf4ef]">Keluar</button>
                </form>
            </div>
        </header>

        <main class="min-h-0 flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
            @if (session('status'))
                <div class="mb-4 rounded-lg bg-green-50 px-4 py-3 text-sm text-green-700">{{ session('status') }}</div>
            @endif
            @yield('content')
        </main>
        <script>
            document.querySelectorAll('form[data-auto-filter]').forEach((form) => {
                form.querySelectorAll('select, input[type="date"]').forEach((field) => field.addEventListener('change', () => form.requestSubmit()));
                form.querySelectorAll('input[type="number"]').forEach((field) => field.addEventListener('change', () => form.requestSubmit()));
                form.querySelectorAll('input[type="search"], input[name="action"]').forEach((field) => {
                    let timer;
                    field.addEventListener('input', () => {
                        clearTimeout(timer);
                        timer = setTimeout(() => form.requestSubmit(), 350);
                    });
                });
                form.querySelector('button[type="submit"]')?.remove();
            });
        </script>
    </div>
</div>
@endsection
