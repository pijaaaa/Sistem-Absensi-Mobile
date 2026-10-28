import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:mobile/core/providers/app_state_provider.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/services/push_notification_service.dart';
import 'package:mobile/core/services/session_manager.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile/features/attendance/data/local/workmanager_service.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:mobile/firebase_options.dart';

Future<RemoteMessage?> _initializeFirebase(SharedPreferences prefs) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final fcm = FirebaseMessaging.instance;

  // Permission diminta setelah login (lihat LoginScreen), bukan di splash.
  // FCM token dapat didapat & diregister meski belum ada permission.

  // Dapatkan token, simpan ke pref, dan sediakan listener refresh.
  try {
    final token = await fcm.getToken();
    if (token != null && token.isNotEmpty) {
      await prefs.setString(StorageKeys.fcmToken, token);
      debugPrint('[FCM] Token: $token');
    }
  } catch (e) {
    debugPrint('[FCM] getToken error: $e');
  }

  await PushNotificationService.instance.initialize();

  // Token refresh → simpan pref + register ulang ke backend (callback diset HomeScreen).
  fcm.onTokenRefresh.listen((token) async {
    if (token.isNotEmpty) {
      await prefs.setString(StorageKeys.fcmToken, token);
      PushNotificationService.onTokenRefreshed?.call(token);
    }
  });

  // Foreground: FCM tidak menampilkan notifikasi otomatis → tampilkan lokal.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('[FCM] onMessage: ${message.notification?.title}');
    PushNotificationService.instance.showFromMap(message.toMap());
  });

  // Ketuk notifikasi (background/terminated) → navigasi per data.type.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('[FCM] onMessageOpenedApp: ${message.notification?.title}');
    PushNotificationService.handleNotificationTap(
      Map<String, dynamic>.from(message.data),
    );
  });

  // Foreground local-notification tap sudah di-handle di PushNotificationService.initialize
  // (onDidReceiveNotificationResponse → handleNotificationTap).

  // Background/terminated data-only messages (diperlukan agar handler terdaftar).
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Notifikasi yang membuka app dari terminated state (cold start).
  return fcm.getInitialMessage();
}

  // (Foreground/local-notif tap & background tap navigation di-handle oleh
  //  PushNotificationService.handleNotificationTap via navigatorKey.)

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[FCM] background: ${message.notification?.title}');
  await PushNotificationService.instance.initialize();
  await PushNotificationService.instance.showFromMap(message.toMap());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences before app starts (needed for auth session)
  final prefs = await SharedPreferences.getInstance();

  // Baca onboarding flag dan token sebelum runApp — berikan ke provider sebagai initial value
  final onboardingDonePref = prefs.getBool(StorageKeys.onboardingSeen) ?? false;
  final tokenPref = prefs.getString(StorageKeys.accessToken);
  final isLoggedInPref = tokenPref != null && tokenPref.isNotEmpty;

  SessionManager.setPrefs(prefs);
   RemoteMessage? initialMessage;
  try {
    initialMessage = await _initializeFirebase(prefs);
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

  // 1. Connectivity monitoring using connectivity_plus to trigger sync when network returns
  Connectivity().onConnectivityChanged.listen((results) async {
    final isOnline = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet
    );
    if (isOnline) {
      try {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
        );
        final offlineService = container.read(offlineAttendanceServiceProvider);
        await offlineService.syncPendingAttendances();
      } catch (_) {}
    }
  });

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

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appStateProvider.overrideWith(
          (ref) => AppStateNotifier.withInitialState(
            prefsInstance: prefs,
            isLoggedIn: isLoggedInPref,
            onboardingDone: onboardingDonePref,
          ),
        ),
      ],
      child: const AbsensiApp(),
    ),
  );

  // Cold-start: app dibuka via notifikasi (terminated state). Jika belum login,
  // handleNotificationTap menyimpan ke pendingNavigation; Home consume setelah login.
  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.handleNotificationTap(
        Map<String, dynamic>.from(initialMessage!.data),
      );
    });
  }
}

class AbsensiApp extends ConsumerWidget {
  const AbsensiApp({super.key});

  static final _exitAttempt = <DateTime>[];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Setup 401 callback — trigger logout on expired token from Dio interceptor
    SessionManager.onSessionExpired ??= () {
      ref.read(appStateProvider.notifier).logout();
    };

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

