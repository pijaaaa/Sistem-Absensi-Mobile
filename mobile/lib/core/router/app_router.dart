import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/approval/presentation/screens/approval_screen.dart';
import 'package:mobile/features/attendance/presentation/screens/attendance_flow_screen.dart';
import 'package:mobile/features/attendance/presentation/screens/history_screen.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/design_showcase/design_showcase_screen.dart';
import 'package:mobile/features/face/presentation/screens/enrollment_screen.dart';
import 'package:mobile/features/home/presentation/screens/home_screen.dart';
import 'package:mobile/features/leave/presentation/screens/leave_screen.dart';
import 'package:mobile/features/notification/presentation/screens/notification_screen.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:mobile/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefreshStream(ref),
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;
      final loggingIn = location == '/login';
      final goingHome = location == '/home';
      final isFirst = location == '/splash';

      if (isAuthenticated && (loggingIn || isFirst)) return '/home';
      if (!isAuthenticated && !loggingIn && !isFirst) return '/login';
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

class _AuthRefreshStream extends ChangeNotifier {
  _AuthRefreshStream(this.ref) {
    ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
}

// A placeholder home screen that shows the app is working
class HomeScreenPlaceholder extends ConsumerWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('F0 Foundation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang, ${authState.user?.name ?? "Pengguna"}!',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Role: ${authState.user?.role ?? "N/A"}'),
            const SizedBox(height: 16),
            const Text('Menu yang tersedia:'),
            ...authState.menus.map(
              (menu) => ListTile(
                leading: Icon(_getIcon(menu['icon'] as String? ?? '')),
                title: Text(menu['label'] as String? ?? 'Menu'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Navigation dinamis dan FCM akan dikerjakan di milestone selanjutnya.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _getIcon(String iconName) {
  switch (iconName) {
    case 'home':
      return Icons.home;
    case 'fingerprint':
      return Icons.fingerprint;
    case 'calendar':
      return Icons.calendar_today;
    case 'document':
      return Icons.document_scanner;
    case 'person':
      return Icons.person;
    case 'check_circle':
      return Icons.check_circle;
    case 'bar_chart':
      return Icons.bar_chart;
    case 'bell':
      return Icons.notifications;
    default:
      return Icons.menu;
  }
}
