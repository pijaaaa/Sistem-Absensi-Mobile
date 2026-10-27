<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Console\Command;

/**
 * Dev-only helper: kirim push uji ke satu user (Fase 0 end-to-end test).
 *
 * Usage:  php artisan notif:test {user_id} {--type=test} {--title=...} {--body=...}
 */
class TestNotificationCommand extends Command
{
    protected $signature = 'notif:test
                            {user_id : ID user yang dituju}
                            {--type=test : data.type yang dikirim ke mobile}
                            {--title=Test Notifikasi : Judul notifikasi}
                            {--body=Ini notifikasi uji dari backend : Body notifikasi}';

    protected $description = 'Kirim notifikasi tes push ke satu user (development only)';

    public function handle(NotificationService $notifier): int
    {
        $id = (int) $this->argument('user_id');
        $user = User::find($id);

        if (! $user) {
            $this->error("User #{$id} tidak ditemukan.");

            return self::FAILURE;
        }

        $tokenCount = $user->pushTokens()->count();
        if ($tokenCount === 0) {
            $this->warn("User {$user->email} belum memiliki push token. Login dulu di mobile app.");
        }

        $type = (string) $this->option('type');
        $title = (string) $this->option('title');
        $body = (string) $this->option('body');

        $notification = $notifier->send($user, $title, $body, [
            'type' => $type,
            'source' => 'notif:test',
        ]);

        if ($notification) {
            $this->info("Notifikasi terkirim ke {$user->email} (token: {$tokenCount}). notification_id={$notification->id}, type={$type}");
        } else {
            $this->warn("Notifikasi dilewati untuk {$user->email} (dedupe).");
        }

        return self::SUCCESS;
    }
}
