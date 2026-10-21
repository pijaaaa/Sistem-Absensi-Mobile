import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/features/attendance/data/local/workmanager_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize background sync
  await WorkManagerService.initialize();
  await WorkManagerService.registerPeriodicSync();

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

