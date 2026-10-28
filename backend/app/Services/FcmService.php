<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Google\Auth\FetchAuthTokenCache;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Pengirim push FCM via HTTP v1 (endpoint messages:send) dengan OAuth2
 * bearer dari service-account. Token di-cache 55 menit (buffer dari 1h).
 *
 * Status kirim per token:
 *   'ok'       — berhasil
 *   'invalid'  — token ditolak (UNREGISTERED/NOT_FOUND/INVALID_ARGUMENT/ PERMISSION_DENIED)
 *   'error'    — error sementara (5xx/timeout) — boleh di-retry oleh queue worker
 */
class FcmService
{
    private string $projectId;

    private ?string $serviceAccountPath;

    public function __construct(?string $projectId = null, ?string $serviceAccountPath = null)
    {
        $this->projectId = (string) ($projectId ?? config('services.fcm.project_id'));
        $this->serviceAccountPath = $serviceAccountPath ?? config('services.fcm.service_account_json');
    }

    /**
     * @return array<string>|null
     */
    private function serviceAccountConfig(): ?array
    {
        if (! $this->serviceAccountPath || ! file_exists($this->serviceAccountPath)) {
            Log::warning('[FCM] service account JSON tidak dikonfigurasi atau tidak ditemukan: '.(string) $this->serviceAccountPath);

            return null;
        }

        $raw = file_get_contents($this->serviceAccountPath);

        return json_decode($raw ?: '', true) ?: null;
    }

    private function fetchAccessToken(): string
    {
        $config = $this->serviceAccountConfig();

        if (! $config) {
            throw new \RuntimeException('Firebase service account tidak tersedia (env FIREBASE_SERVICE_ACCOUNT_JSON).');
        }

        $credentials = new ServiceAccountCredentials(
            'https://www.googleapis.com/auth/firebase.messaging',
            $config,
        );

        // FetchAuthTokenCache otomatis refresh & cache (in-memory) token.
        $cache = new FetchAuthTokenCache($credentials);
        $token = $cache->fetchAuthToken();

        if (empty($token['access_token'])) {
            throw new \RuntimeException('[FCM] fetchAccessToken gagal: '.($token['error'] ?? 'unknown'));
        }

        return $token['access_token'];
    }

    private function accessToken(): string
    {
        return (string) Cache::remember('fcm.access_token', now()->addMinutes(55), fn () => $this->fetchAccessToken());
    }

    private function endpoint(): string
    {
        return sprintf('https://fcm.googleapis.com/v1/projects/%s/messages:send', $this->projectId);
    }

    /**
     * Channel id Android berdasarkan data.type (harus didaftarkan di mobile).
     */
    public function channelFor(?string $type): string
    {
        return match ($type) {
            'reminder_checkin', 'reminder_checkout', 'reminder_forgot_checkout' => 'channel_reminder',
            'leave_request_new', 'backup_attendance_request', 'pending_approval_digest' => 'channel_approval',
            default => 'channel_info',
        };
    }

    /**
     * Kirim ke satu token.
     */
    public function sendToOne(string $token, string $title, string $body, array $data = [], ?string $channelId = null): string
    {
        if (! $this->projectId) {
            Log::info('[FCM] project_id kosong, push dilewati.');

            return 'error';
        }

        $payload = [
            'message' => [
                'token' => $token,
                'notification' => ['title' => $title, 'body' => $body],
                'data' => array_map('strval', $data),
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'channel_id' => $channelId ?? $this->channelFor($data['type'] ?? null),
                        'visibility' => 'private',
                        'sound' => 'default',
                        'default_sound' => true,
                        'default_vibrate_timings' => true,
                    ],
                ],
                'apns' => ['payload' => ['aps' => ['sound' => 'default']]],
            ],
        ];

        try {
            $response = Http::withToken($this->accessToken())
                ->timeout(10)
                ->post($this->endpoint(), $payload);
        } catch (\Throwable $e) {
            Log::warning('[FCM] sendToOne network failure: '.$e->getMessage(), ['token' => substr($token, 0, 16)]);

            return 'error';
        }

        // HTTP 200 → berhasil.
        if ($response->successful()) {
            return 'ok';
        }

        $error = $response->json('error');
        $status = is_array($error) ? ($error['status'] ?? null) : null;
        $message = is_array($error) ? ($error['message'] ?? $response->body()) : $response->body();

        Log::warning('[FCM] sendToOne gagal: '.$message, [
            'http' => $response->status(),
            'fcm_status' => $status,
            'token' => substr($token, 0, 16).'...',
        ]);

        return match ($status) {
            'UNREGISTERED', 'NOT_FOUND', 'INVALID_ARGUMENT', 'PERMISSION_DENIED', 'UNIMPLEMENTED' => 'invalid',
            default => 'error',
        };
    }

    /**
     * Backward-compat: kirim ke banyak token; kembalikan token yang valid
     * (caller / job yang menghapus token yang invalid).
     *
     * @param  array<int, string>  $tokens
     * @param  array<string, mixed>  $data
     * @return array<int, string>
     */
    public function send(array $tokens, string $title, string $body, array $data = []): array
    {
        if (empty($tokens) || ! $this->projectId) {
            return [];
        }

        $valid = [];

        foreach ($tokens as $token) {
            if ($this->sendToOne($token, $title, $body, $data) === 'ok') {
                $valid[] = $token;
            }
        }

        return $valid;
    }
}
