<?php

namespace App\Services;

use App\Jobs\SendPushNotification;
use App\Models\Employee;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\User;
use Illuminate\Support\Collection;

class NotificationService
{
    /**
     * Approver pengajuan: manager department yang sama untuk karyawan,
     * atau superadmin bila pengaju adalah manager.
     *
     * @return Collection<int, User>
     */
    public function approversFor(Employee $requester): Collection
    {
        if ($requester->user?->role->value === 'manager_department') {
            return User::where('role', 'superadmin')->get();
        }

        return User::where('role', 'manager_department')
            ->whereHas('employee', fn ($q) => $q->where('department_id', $requester->department_id))
            ->get();
    }

    /**
     * Simpan notifikasi ke DB + kirim push lewat queue (job per user).
     *
     * $data wajib mengandung 'type' (lihat tabel data.type di roadmap) agar
     * mobile tahu layar tujuan saat notifikasi diketuk. Jika $dedupeKey sudah
     * ada untuk user yang sama → notifikasi dilewati (anti-duplicate).
     *
     * @param  array<string, mixed>  $data
     */
    public function send(User $user, string $title, string $body, array $data = [], ?string $dedupeKey = null): ?Notification
    {
        if (empty($data['type'])) {
            throw new \InvalidArgumentException('NotificationService::send wajib menerima data[type].');
        }

        $type = $data['type'];

        if (in_array($type, NotificationPreference::$toggleableTypes, true)
            && ! NotificationPreference::isEnabled($user->id, $type)) {
            return null;
        }

        if ($dedupeKey !== null && $user->appNotifications()->where('dedupe_key', $dedupeKey)->exists()) {
            return null;
        }

        $notification = $user->appNotifications()->create([
            'title' => $title,
            'body' => $body,
            'data_json' => $data,
            'dedupe_key' => $dedupeKey,
        ]);

        SendPushNotification::dispatch($notification->id, $user->id, $title, $body, $data);

        return $notification;
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function sendMany(iterable $users, string $title, string $body, array $data = [], ?string $dedupeKey = null): void
    {
        // Pastikan list user unique untuk mencegah duplikasi kirim ke user yang sama (misal role tumpang tindih)
        $uniqueUsers = collect($users)->unique('id');
        foreach ($uniqueUsers as $user) {
            $this->send($user, $title, $body, $data, $dedupeKey);
        }
    }
}
