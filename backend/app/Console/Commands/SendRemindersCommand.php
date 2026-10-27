<?php

namespace App\Console\Commands;

use App\Services\AttendanceReminderService;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('notifications:send-reminders')]
class SendRemindersCommand extends Command
{
    public function handle(AttendanceReminderService $service): int
    {
        $count = $service->sendDue();

        $this->info("Reminder dikirim: {$count} notifikasi (DB record + queue job).");

        return self::SUCCESS;
    }
}
