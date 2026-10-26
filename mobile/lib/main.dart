import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/services/push_notification_service.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/features/attendance/data/local/workmanager_service.dart';
import 'package:mobile/firebase_options.dart';

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final fcm = FirebaseMessaging.instance;

  // Request notification permission
  final settings = await fcm.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.denied ||
      settings.authorizationStatus == AuthorizationStatus.notDetermined) {
    // permission not granted — still proceed, FCM token may not be available
  }

  // Get and log FCM token (registration on backend deferred to login flow)
  try {
    final token = await fcm.getToken();
    debugPrint('[FCM] Token: $token');
  } catch (e) {
    debugPrint('[FCM] getToken error: $e');
  }

  // Initialize local notification service for foreground handling
  await PushNotificationService.instance.initialize();
  await PushNotificationService.instance.requestPermission();

  // Configure message handlers
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('[FCM] onMessage: ${message.notification?.title}');
    final data = message.toMap();
    PushNotificationService.instance.showFromMap(data);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('[FCM] onMessageOpenedApp: ${message.notification?.title}');
  });

  // Handle background/terminated messages via top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Must call initialize if background isolate runs without it
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[FCM] background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase + FCM
  try {
    await _initializeFirebase();
  } catch (e) {
    debugPrint('[FCM] Initialization error: $e');
  }

  // Initialize locale data for date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize background sync (non-fatal: ignore if Workmanager unavailable)
  try {
    await WorkManagerService.initialize();
    await WorkManagerService.registerPeriodicSync();
  } catch (e) {
    // ignore — bg sync optional, must not crash app startup
  }

  // Catch-all: avoid black screen on unexpected widget errors, log to console
  ErrorWidget.builder = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Terjadi kesalahan:\n${details.exception}',
                style: TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  runApp(const ProviderScope(child: AbsensiApp()));
}

class AbsensiApp extends ConsumerWidget {
  const AbsensiApp({super.key});

  static final _exitAttempt = <DateTime>[];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final goRouter = GoRouter.maybeOf(context);
        if (goRouter != null && goRouter.canPop()) {
          goRouter.pop();
          return;
        }

        final now = DateTime.now();
        _exitAttempt
          ..removeWhere((t) => now.difference(t).inSeconds > 2)
          ..add(now);

        if (_exitAttempt.length >= 2) {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: MaterialApp.router(
        title: 'Absensi - PT Bumi Siak Pusako',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}

