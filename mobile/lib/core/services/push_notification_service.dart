import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service untuk menampilkan notifikasi lokal (foreground) + request permission.
///
/// FCM menampilkan notifikasi otomatis di background/terminated secara native.
/// Service ini hanya dipakai untuk foreground messages agar tetap muncul
/// notifikasi saat app terbuka.
class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  factory PushNotificationService() => instance;
  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  static const channelId = 'absensi_channel';
  static const channelName = 'Notifikasi Absensi';
  static const channelDesc =
      'Notifikasi dari sistem absensi PT Bumi Siak Pusako';

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();

    await _fln.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
  }

  Future<void> requestPermission() async {
    final android = _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> showFromMap(Map<String, dynamic> message) async {
    final title = message['title']?.toString() ?? 'Notifikasi Baru';
    final body = message['body']?.toString() ?? '';
    final data = message['data'] is Map ? Map<String, dynamic>.from(message['data']) : null;

    const android = AndroidNotificationDetails(
      channelId, channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iOS = DarwinNotificationDetails();

    await _fln.show(
      0,
      title,
      body,
      const NotificationDetails(android: android, iOS: iOS),
      payload: data != null ? data.toString() : null,
    );
  }
}
