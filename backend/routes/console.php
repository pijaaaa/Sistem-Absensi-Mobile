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

