<?php

namespace App\Enums;

enum PermissionAction: string
{
    case View = 'view';
    case Create = 'create';
    case Update = 'update';
    case Delete = 'delete';
    case Export = 'export';
    case Approve = 'approve';

    /**
     * Aksi standar yang selalu tersedia untuk setiap modul.
     *
     * @return array<int, self>
     */
    public static function standard(): array
    {
        return [self::View, self::Create, self::Update, self::Delete];
    }

    public function label(): string
    {
        return match ($this) {
            self::View => 'Lihat',
            self::Create => 'Tambah',
            self::Update => 'Ubah',
            self::Delete => 'Hapus',
            self::Export => 'Ekspor',
            self::Approve => 'Approve',
        };
    }
}
