@extends('layouts.admin')

@section('title', 'Profil Akun')

@section('content')
<div class="max-w-xl rounded-xl border border-[#dce7e0] bg-white p-6 shadow-[0_2px_8px_rgba(16,36,27,0.035)]">
    <h2 class="text-lg font-bold text-neutral-dark">Profil Akun</h2>
    <p class="mt-1 text-sm text-gray-500">Ubah nama dan password akun {{ auth()->user()->role->label() }}.</p>

    <form method="POST" action="{{ route('profile.update') }}" class="mt-6 space-y-4">
        @csrf
        @method('PUT')
        <div>
            <label class="mb-1.5 block text-sm font-semibold text-primary">Nama</label>
            <input name="name" value="{{ old('name', auth()->user()->name) }}" required class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('name') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <div>
            <label class="mb-1.5 block text-sm font-semibold text-primary">Password baru</label>
            <input type="password" name="password" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <p class="mt-1 text-xs text-gray-500">Kosongkan jika tidak ingin mengganti password. Minimal 8 karakter.</p>
            @error('password') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <div>
            <label class="mb-1.5 block text-sm font-semibold text-primary">Konfirmasi password</label>
            <input type="password" name="password_confirmation" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
        </div>
        <button class="rounded-lg bg-primary px-4 py-2.5 text-sm font-bold text-white hover:bg-primary/90">Simpan Perubahan</button>
    </form>
</div>
@endsection
