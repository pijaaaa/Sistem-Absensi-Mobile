<?php

namespace App\Console\Commands;

use App\Models\Notification;
use App\Models\Setting;
use Carbon\Carbon;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('notifications:purge-old')]
#[Description('Hapus notifikasi lebih tua dari N hari (retensi, Fase 2).')]
class PurgeOldNotificationsCommand extends Command
{
    public function handle(): int
    {
        $days = (int) Setting::get('notif_retention_days', 90);
        $cutoff = Carbon::now()->subDays($days);

        $deleted = Notification::where('created_at', '<', $cutoff)->delete();

        $this->info("Notifikasi dihapus: {$deleted} (lebih tua dari {$days} hari).");

        return self::SUCCESS;
    }
}
