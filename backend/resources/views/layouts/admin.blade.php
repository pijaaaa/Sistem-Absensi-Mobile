@php
    $sidebar = app(\App\Support\Access\MenuService::class)->forRole(auth()->user()->role, 'web');
@endphp
@extends('layouts.app')

@section('body')
<div class="flex min-h-full">
    <aside class="hidden w-64 shrink-0 flex-col border-r bg-white md:flex">
        <div class="border-b px-6 py-4">
            <span class="text-lg font-semibold">Absensi</span>
        </div>
        <nav class="flex-1 space-y-1 overflow-y-auto p-3">
            @foreach ($sidebar as $menu)
                @php($href = \Illuminate\Support\Facades\Route::has($menu->route_or_feature_key) ? route($menu->route_or_feature_key) : '#')
                <a href="{{ $href }}"
                    class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm {{ request()->routeIs($menu->route_or_feature_key) ? 'bg-gray-900 text-white' : 'text-gray-700 hover:bg-gray-100' }}">
                    <span class="text-xs uppercase text-gray-400">{{ Str::substr($menu->icon ?? '', 0, 2) }}</span>
                    <span>{{ $menu->label }}</span>
                </a>
            @endforeach
        </nav>
    </aside>

    <div class="flex min-w-0 flex-1 flex-col">
        <header class="flex items-center justify-between border-b bg-white px-6 py-4">
            <h1 class="text-lg font-semibold">@yield('title', 'Admin')</h1>
            <div class="flex items-center gap-4">
                <span class="text-sm text-gray-600">{{ auth()->user()->name }}</span>
                <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button type="submit" class="text-sm text-red-600 hover:underline">Keluar</button>
                </form>
            </div>
        </header>

        <main class="flex-1 p-6">
            @if (session('status'))
                <div class="mb-4 rounded-lg bg-green-50 px-4 py-3 text-sm text-green-700">{{ session('status') }}</div>
            @endif
            @yield('content')
        </main>
    </div>
</div>
@endsection
