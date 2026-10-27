import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/router/app_router.dart';

/// Service untuk menampilkan notifikasi lokal (foreground) + request permission.
///
/// FCM (firebase_messaging) menampilkan notifikasi native secara otomatis di
/// background/terminated. Service ini hanya dipakai untuk:
///  - foreground messages (FCM tidak menampilkannya di foreground)
///  - request permission Android 13+ (POST_NOTIFICATIONS)
///  - navigation saat notifikasi diketuk (foreground local / ketuk di bg/terminated)
///  - token lifecycle (register/refresh/delete) lewat callback yang diset app
class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  factory PushNotificationService() => instance;
  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  // Diset oleh app (HomeScreen) agar service tidak butuh context/refs.
  static void Function(String token)? onTokenRefreshed;
  static void Function(String token)? onDeleteToken;
  static bool Function()? isAuthorized; // set Home → cek login state
  static void Function()? onRequestNotificationSettings; // open app settings

  // Notification channels (harus didaftarkan sebelum notifikasi tampil).
  static const channelReminder = AndroidNotificationChannel(
    'channel_reminder',
    'Pengingat Absensi',
    description: 'Pengingat masuk/keluar dan lupa absen.',
    importance: Importance.high,
  );
  static const channelApproval = AndroidNotificationChannel(
    'channel_approval',
    'Persetujuan',
    description: 'Pengajuan cuti/izin dan approval device cadangan.',
    importance: Importance.high,
  );
  static const channelInfo = AndroidNotificationChannel(
    'channel_info',
    'Informasi',
    description: 'Notifikasi penting lainnya.',
    importance: Importance.high,
  );

  static const String channelIdReminder = 'channel_reminder';
  static const String channelIdApproval = 'channel_approval';
  static const String channelIdInfo = 'channel_info';

  Future<void> initialize() async {
    // Daftarkan channel supaya notifikasi (termasuk background) pakai channel yang tepat.
    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(channelReminder);
      await android.createNotificationChannel(channelApproval);
      await android.createNotificationChannel(channelInfo);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings();

    await _fln.initialize(
      const InitializationSettings(android: androidInit, iOS: iOSInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          handleNotificationTap(_decodePayload(payload));
        }
      },
    );
  }

  /// Android 13+ (API 33) — minta POST_NOTIFICATIONS. Dipanggil setelah login
  /// (bukan di splash), dengan pesan jika ditolak.
  Future<bool> requestPermission(BuildContext? context) async {
    final android = _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? false;

    if (!granted && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Notifikasi tidak aktif. Aktifkan di Pengaturan agar tidak kelewat absen.'),
          action: SnackBarAction(
              label: 'Buka Pengaturan',
              onPressed: () => onRequestNotificationSettings?.call()),
        ),
      );
    }

    return granted;
  }

  static String channelIdForType(String? type) => switch (type) {
        'reminder_checkin' ||
        'reminder_checkout' ||
        'reminder_forgot_checkout' => channelIdReminder,
        'leave_request_new' ||
        'backup_attendance_request' ||
        'pending_approval_digest' => channelIdApproval,
        _ => channelIdInfo,
      };

  static String routeForType(String? type) => switch (type) {
        'reminder_checkin' ||
        'reminder_checkout' ||
        'reminder_forgot_checkout' ||
        'absent_marked' => '/home',
        'leave_request_new' ||
        'backup_attendance_request' ||
        'pending_approval_digest' => '/approval',
        'leave_decision' ||
        'backup_attendance_decision' ||
        'offline_sync_result' => '/history',
        'leave_balance_expiring' => '/leave',
        'device_registered' => '/profile',
        _ => '/notifications',
      };

  /// Tampilkan notifikasi lokal (foreground). `message` = RemoteMessage.toMap().
  Future<void> showFromMap(Map<String, dynamic> message) async {
    final notification = message['notification'] as Map<String, dynamic>?;
    final data = _coerceData(message['data']);
    final String? type = _asString(data['type']);

    final title = _asString(notification?['title']) ??
        _asString(data['title']) ??
        'Notifikasi Baru';
    final body = _asString(notification?['body']) ?? _asString(data['body']) ?? '';

    final channelId = channelIdForType(type);
    final androidDetails = androidDetailsFor(channelId);
    const iOSDetails = DarwinNotificationDetails();

    await _fln.show(
      (data['id'] ?? data['notification_id']) is int
          ? data['id'] as int
          : _hashId(type, data),
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      ),
      payload: _encodePayload({'type': type, ...data}),
    );
  }

  AndroidNotificationDetails androidDetailsFor(String channelId) => switch (channelId) {
        channelIdReminder => const AndroidNotificationDetails(
            channelIdReminder,
            'Pengingat Absensi',
            channelDescription:
                'Pengingat masuk/keluar dan lupa absen.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        channelIdApproval => const AndroidNotificationDetails(
            channelIdApproval,
            'Persetujuan',
            channelDescription:
                'Pengajuan cuti/izin dan approval device cadangan.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        _ => const AndroidNotificationDetails(
            channelIdInfo,
            'Informasi',
            channelDescription: 'Notifikasi penting lainnya.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
      };

  // ---- Navigasi tap notifikasi ----

  /// Simpan notifikasi yang membuka app dari terminated state, agar setelah
  /// login (atau ketika router siap) dapat di-navigate.
  static PendingNavigation? pendingNavigation;

  static Map<String, dynamic> _coerceData(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  static String? _asString(dynamic v) => v == null ? null : v.toString();

  static int _hashId(String? type, Map data) =>
      '$type:${data['id']}'.hashCode & 0x7fffffff;

  static String _encodePayload(Map<String, dynamic> data) =>
      jsonEncode(data);

  static Map<String, dynamic> _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  /// Navigasi sesuai data.type. Jika router belum siap atau user belum login,
  /// simpan ke [pendingNavigation] agar dikonsumsi oleh Home setelah login.
  static void handleNotificationTap(Map<String, dynamic> data) {
    final type = _asString(data['type']);
    final route = routeForType(type);

    // Belum login (mis. cold start) → simpan, konsumsi di Home setelah login.
    if (!(isAuthorized?.call() ?? false)) {
      pendingNavigation = PendingNavigation(type: type, route: route, data: data);
      return;
    }

    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      pendingNavigation = PendingNavigation(type: type, route: route, data: data);
      return;
    }

    final router = GoRouter.maybeOf(ctx);
    if (router == null) {
      pendingNavigation = PendingNavigation(type: type, route: route, data: data);
      return;
    }

    router.go(route, extra: {'notif_type': type, 'id': data['id']});
  }

  /// Dipanggil di HomeScreen setelah login untuk memproses pending navigation.
  static PendingNavigation? consumePendingNavigation() {
    final pending = pendingNavigation;
    pendingNavigation = null;
    return pending;
  }
}

class PendingNavigation {
  final String? type;
  final String route;
  final Map<String, dynamic> data;

  PendingNavigation({
    required this.type,
    required this.route,
    required this.data,
  });
}
