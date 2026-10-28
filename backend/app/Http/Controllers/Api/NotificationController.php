<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\PushToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function registerToken(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'max:4096'],
            'platform' => ['nullable', 'in:android'],
        ]);

        PushToken::updateOrCreate(
            ['token' => $data['token']],
            ['user_id' => $request->user()->id, 'platform' => $data['platform'] ?? 'android']
        );

        return response()->json(['success' => true, 'message' => 'Token tersimpan.', 'data' => null]);
    }

    /**
     * Hapus token (dipanggil saat logout / token invalid).
     */
    public function deleteToken(Request $request, string $token): JsonResponse
    {
        $deleted = $request->user()->pushTokens()->where('token', $token)->delete();

        return response()->json([
            'success' => true,
            'message' => $deleted ? 'Token dihapus.' : 'Token tidak ditemukan.',
            'data' => null,
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        $notifications = $request->user()->appNotifications()->latest()->paginate(50);

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => $notifications->map(fn (Notification $n) => [
                'id' => $n->id,
                'title' => $n->title,
                'body' => $n->body,
                'data' => $n->data_json,
                'read_at' => $n->read_at?->toIso8601String(),
                'created_at' => $n->created_at->toIso8601String(),
            ]),
        ]);
    }

    public function markRead(Request $request, Notification $notification): JsonResponse
    {
        if ($notification->user_id !== $request->user()->id) {
            abort(403, 'Bukan notifikasi Anda.');
        }

        $notification->update(['read_at' => now()]);

        return response()->json(['success' => true, 'message' => 'Notifikasi ditandai dibaca.', 'data' => null]);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        $request->user()->appNotifications()->whereNull('read_at')->update(['read_at' => now()]);

        return response()->json(['success' => true, 'message' => 'Semua notifikasi ditandai dibaca.', 'data' => null]);
    }

    public function preferences(Request $request): JsonResponse
    {
        $user = $request->user();
        $prefs = $user->notificationPreferences()->pluck('enabled', 'type');

        $result = [];
        foreach (NotificationPreference::$toggleableTypes as $type) {
            $result[$type] = $prefs[$type] ?? true;
        }

        return response()->json(['success' => true, 'message' => 'OK', 'data' => $result]);
    }

    public function updatePreferences(Request $request): JsonResponse
    {
        $data = $request->validate([
            'preferences' => ['required', 'array'],
            'preferences.*' => ['boolean'],
        ]);

        $user = $request->user();

        foreach ($data['preferences'] as $type => $enabled) {
            if (! in_array($type, NotificationPreference::$toggleableTypes, true)) {
                continue;
            }

            NotificationPreference::updateOrCreate(
                ['user_id' => $user->id, 'type' => $type],
                ['enabled' => $enabled],
            );
        }

        return response()->json(['success' => true, 'message' => 'Preferensi diperbarui.', 'data' => null]);
    }
}
