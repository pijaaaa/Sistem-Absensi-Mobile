<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Pengirim push FCM. Memakai endpoint legacy `fcm/send` + server key dari .env.
 * ponytail: legacy masih dipakai agar sederhana; pindah ke HTTP v1 (service account)
 * saat production (lihat README, langkah Firebase console).
 */
class FcmService
{
    public function __construct(
        private ?string $serverKey = null,
        private string $url = 'https://fcm.googleapis.com/fcm/send',
    ) {}

    /**
     * @param  array<int, string>  $tokens
     * @param  array<string, mixed>  $data
     */
    public function send(array $tokens, string $title, string $body, array $data = []): void
    {
        if (empty($tokens)) {
            return;
        }

        if (! $this->serverKey) {
            Log::info('[FCM] server key kosong, push dilewati.', ['title' => $title, 'tokens' => count($tokens)]);

            return;
        }

        foreach (array_chunk($tokens, 500) as $chunk) {
            Http::withHeaders([
                'Authorization' => 'key='.$this->serverKey,
                'Content-Type' => 'application/json',
            ])->timeout(10)->post($this->url, [
                'registration_ids' => $chunk,
                'notification' => ['title' => $title, 'body' => $body],
                'data' => $data,
            ]);
        }
    }
}
