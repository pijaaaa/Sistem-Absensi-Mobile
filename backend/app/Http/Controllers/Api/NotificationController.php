<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
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
}
