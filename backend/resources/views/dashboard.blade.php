@extends('layouts.app')

@section('title', 'Dashboard')

@section('body')
<div class="min-h-full">
    <header class="flex items-center justify-between border-b bg-white px-6 py-4">
        <h1 class="text-lg font-semibold">Dashboard Admin</h1>
        <div class="flex items-center gap-4">
            <span class="text-sm text-gray-600">{{ auth()->user()->name }}</span>
            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button type="submit" class="text-sm text-red-600 hover:underline">Keluar</button>
            </form>
        </div>
    </header>

    <main class="mx-auto max-w-5xl p-6">
        <p class="text-gray-600">Selamat datang di web admin sistem absensi.</p>
    </main>
</div>
@endsection
