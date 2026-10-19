@extends('layouts.app')

@section('title', 'Masuk')

@section('body')
<div class="flex min-h-full items-center justify-center px-4">
    <div class="w-full max-w-sm rounded-xl bg-white p-8 shadow">
        <h1 class="mb-1 text-xl font-semibold">Admin Absensi</h1>
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
                    class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-gray-900 focus:outline-none">
            </div>
            <div>
                <label for="password" class="mb-1 block text-sm font-medium">Password</label>
                <input id="password" name="password" type="password" required
                    class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-gray-900 focus:outline-none">
            </div>
            <label class="flex items-center gap-2 text-sm">
                <input type="checkbox" name="remember" value="1" class="rounded border-gray-300">
                Ingat saya
            </label>
            <button type="submit"
                class="w-full rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">
                Masuk
            </button>
        </form>
    </div>
</div>
@endsection
