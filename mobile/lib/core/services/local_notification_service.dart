import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service untuk menampilkan notifikasi lokal (foreground + background).
///
/// Menggunakan flutter_local_notifications untuk menampilkan notifikasi
/// ketika aplikasi di foreground. Untuk background, Firebase Messaging
/// menampilkan notifikasi secara otomatis (jika payloadnya berisi
/// `notification` key).
class LocalNotificationService {
  static final LocalNotificationService instance = LocalNotificationService._();
  factory LocalNotificationService() => instance;
  LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'absensi_channel';
  static const _channelName = 'Notifikasi Absensi';
  static const _channelDesc = 'Notifikasi dari sistem absensi PT Bumi Siak Pusako';

  bool _initialized = false;

  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const iOS = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
      onSelectNotification: (payload) async {
        // Handle notification tap
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/notifications');
        }
      },
    );

    _initialized = true;
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    const iOS = DarwinNotificationDetails();

    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(android: android, iOS: iOS),
      payload: payload,
    );
  }

  static Future<void> requestPermission() async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}
