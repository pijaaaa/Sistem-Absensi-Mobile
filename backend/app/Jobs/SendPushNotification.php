<?php

namespace App\Jobs;

use App\Models\PushToken;
use App\Models\User;
use App\Services\FcmService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

/**
 * Kirim satu notifikasi push ke satu user via job (driver queue: database).
 * Dipanggil oleh NotificationService::send — satu job per penerima agar
 * 200–500 user tidak menahan scheduler.
 */
class SendPushNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public readonly int $notificationId,
        public readonly int $userId,
        public readonly string $title,
        public readonly string $body,
        public readonly array $data,
    ) {}

    public function handle(FcmService $fcm): void
    {
        $user = User::find($this->userId);

        if (! $user) {
            return;
        }

        $tokens = $user->pushTokens()->pluck('token')->all();

        if (empty($tokens)) {
            return;
        }

        $invalid = [];

        foreach ($tokens as $token) {
            if ($fcm->sendToOne($token, $this->title, $this->body, $this->data) === 'invalid') {
                $invalid[] = $token;
            }
        }

        if (! empty($invalid)) {
            PushToken::whereIn('token', $invalid)->where('user_id', $this->userId)->delete();
        }
    }
}
