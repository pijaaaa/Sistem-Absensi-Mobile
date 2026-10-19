<?php

namespace App\Services;

use App\Models\Employee;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Support\Collection;

class NotificationService
{
    public function __construct(private FcmService $fcm) {}

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
     * @param  array<string, mixed>  $data
     */
    public function send(User $user, string $title, string $body, array $data = []): Notification
    {
        $notification = $user->appNotifications()->create([
            'title' => $title,
            'body' => $body,
            'data_json' => $data,
        ]);

        $this->fcm->send($user->pushTokens()->pluck('token')->all(), $title, $body, $data);

        return $notification;
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function sendMany(iterable $users, string $title, string $body, array $data = []): void
    {
        foreach ($users as $user) {
            $this->send($user, $title, $body, $data);
        }
    }
}
