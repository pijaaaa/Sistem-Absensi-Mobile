@props(['label' => null, 'name', 'type' => 'text', 'value' => null, 'readonly' => false])

@php($error = $errors->has($name))
<div class="mb-4">
    @if ($label)
        <label for="{{ $name }}" class="mb-1 block text-sm font-medium">{{ $label }}</label>
    @endif
    <input id="{{ $name }}" name="{{ $name }}" type="{{ $type }}" value="{{ old($name, $value) }}"
        {{ $readonly ? 'readonly' : '' }}
        class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-gray-900 focus:outline-none @error($name) border-red-500 @enderror">
    @error($name) <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
</div>
