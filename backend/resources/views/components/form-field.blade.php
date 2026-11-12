@props(['label' => null, 'name', 'type' => 'text', 'value' => null, 'readonly' => false])

@php($error = $errors->has($name))
<div class="mb-5">
    @if ($label)
        <label for="{{ $name }}" class="mb-2 block text-xs font-bold uppercase tracking-wide text-primary/70">{{ $label }}</label>
    @endif
    <input id="{{ $name }}" name="{{ $name }}" type="{{ $type }}" value="{{ old($name, $value) }}"
        autocomplete="off" {{ $readonly ? 'readonly' : '' }}
        class="w-full rounded-xl border border-[#cddbd2] bg-[#fbfdfb] px-3.5 py-2.5 text-sm transition placeholder:text-gray-400 focus:border-primary focus:bg-white focus:outline-none focus:ring-4 focus:ring-primary/10 @error($name) border-red-500 @enderror">
    @error($name) <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
</div>
