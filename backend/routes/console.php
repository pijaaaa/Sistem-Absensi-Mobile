<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->command(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command('app:purge-expired-face-captures')->dailyAt('01:00');
Schedule::command('app:mark-absentees')->dailyAt('00:05');

// Push notif: reminder harian tiap 5 menit (waktu target dihitung di within window).
Schedule::command('notifications:send-reminders')
    ->everyFiveMinutes()
    ->name('send-reminders')
    ->withoutOverlapping();

// Fase 2: pengajuan pending >24 jam (1x/hari jam 09:05).
Schedule::command('notifications:pending-approval')
    ->dailyAt('09:05')
    ->name('pending-approval')
    ->withoutOverlapping();

// Fase 2: sisa cuti akan hangus (1x/hari jam 08:00, logic tanggal di command).
Schedule::command('notifications:leave-expiry')
    ->dailyAt('08:00')
    ->name('leave-expiry')
    ->withoutOverlapping();

// Fase 2: retensi notifikasi lama (1x/hari jam 02:00).
Schedule::command('notifications:purge-old')
    ->dailyAt('02:00')
    ->name('purge-old-notif')
    ->withoutOverlapping();

