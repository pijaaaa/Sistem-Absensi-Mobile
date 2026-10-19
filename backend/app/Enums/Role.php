<?php

namespace App\Enums;

enum Role: string
{
    case KARYAWAN = 'karyawan';
    case MANAGER_DEPARTMENT = 'manager_department';
    case SUPERADMIN = 'superadmin';

    public function label(): string
    {
        return match ($this) {
            self::KARYAWAN => 'Karyawan',
            self::MANAGER_DEPARTMENT => 'Manager Department',
            self::SUPERADMIN => 'Superadmin',
        };
    }
}
