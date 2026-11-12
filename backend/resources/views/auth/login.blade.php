@extends('layouts.app')

@section('title', 'Masuk')

@section('body')
<div class="flex min-h-full items-center justify-center bg-primary px-4 py-8">
    <div class="w-full max-w-sm rounded-3xl bg-white p-8 shadow-2xl shadow-neutral-dark/20">
        <h1 class="mb-1 text-2xl font-bold text-neutral-dark">Admin Absensi<span class="text-secondary">.</span></h1>
        <p class="mb-6 text-sm text-gray-500">Masuk khusus superadmin.</p>

        @if ($errors->any())
            <div class="mb-4 rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">
                {{ $errors->first() }}
            </div>
        @endif

        <form method="POST" action="{{ route('login') }}" class="space-y-4" x-data>
            @csrf
            <div>
                <label for="email" class="mb-1 block text-sm font-medium">Email</label>
                <input id="email" name="email" type="email" value="{{ old('email') }}" required autofocus
                    class="w-full rounded-xl border border-[#cddbd2] px-3 py-2.5 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/15">
            </div>
            <div>
                <label for="password" class="mb-1 block text-sm font-medium">Password</label>
                <input id="password" name="password" type="password" required
                    class="w-full rounded-xl border border-[#cddbd2] px-3 py-2.5 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/15">
            </div>
            <label class="flex items-center gap-2 text-sm">
                <input type="checkbox" name="remember" value="1" class="rounded border-gray-300">
                Ingat saya
            </label>
            <button type="submit"
                class="w-full rounded-xl bg-primary px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-primary/20 transition hover:bg-tertiary">
                Masuk
            </button>
        </form>
    </div>
</div>
@endsection
