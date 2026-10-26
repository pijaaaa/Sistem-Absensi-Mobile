import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/app_state_provider.dart';
import 'package:mobile/features/approval/presentation/screens/approval_screen.dart';
import 'package:mobile/features/attendance/presentation/screens/attendance_flow_screen.dart';
import 'package:mobile/features/attendance/presentation/screens/history_screen.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/auth/presentation/screens/device_registration_screen.dart';
import 'package:mobile/features/design_showcase/design_showcase_screen.dart';
import 'package:mobile/features/face/presentation/screens/enrollment_screen.dart';
import 'package:mobile/features/home/presentation/screens/home_screen.dart';
import 'package:mobile/features/leave/presentation/screens/leave_screen.dart';
import 'package:mobile/features/more/presentation/screens/more_screen.dart';
import 'package:mobile/features/notification/presentation/screens/notification_screen.dart';
import 'package:mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:mobile/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final appState = ref.watch(appStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AppStateRefreshStream(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;

      // 1) Splash belum selesai → tetap di splash
      if (!appState.splashDone) {
        if (location != '/splash') return '/splash';
        return null;
      }

      // 2) Sudah login, tapi di splash/onboarding/login → ke home
      if (appState.isLoggedIn) {
        if (location == '/splash' || location == '/onboarding' || location == '/login') {
          return '/home';
        }
        return null;
      }

      // 3) Belum login + belum onboarding → ke onboarding
      if (!appState.onboardingDone) {
        if (location != '/onboarding') return '/onboarding';
        return null;
      }

      // 4) Belum login + sudah onboarding → ke login
      if (location == '/splash' || location == '/onboarding') return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/device-registration',
        builder: (context, state) => const DeviceRegistrationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/attendance-flow',
        builder: (context, state) {
          final isCheckIn = state.uri.queryParameters['isCheckIn'] == 'true';
          return AttendanceFlowScreen(isCheckIn: isCheckIn);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/leave',
        builder: (context, state) => const LeaveScreen(),
      ),
      GoRoute(
        path: '/approval',
        builder: (context, state) => const ApprovalScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/more',
        builder: (context, state) => const MoreScreen(),
      ),
      GoRoute(
        path: '/enrollment',
        builder: (context, state) => const EnrollmentScreen(),
      ),
      GoRoute(
        path: '/design-showcase',
        builder: (context, state) => const DesignShowcaseScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(state.error.toString())),
    ),
  );
});

class _AppStateRefreshStream extends ChangeNotifier {
  _AppStateRefreshStream(this.ref) {
    ref.listen(appStateProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
}
