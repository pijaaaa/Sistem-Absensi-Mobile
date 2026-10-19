<?php

namespace App\Services\Dto;

class LatenessResult
{
    public function __construct(
        public readonly int $minutes,
        public readonly ?string $label,
        public readonly ?string $color,
        public readonly bool $countedLate,
    ) {}
}
