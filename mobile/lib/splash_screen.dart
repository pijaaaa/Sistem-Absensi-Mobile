import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/startup_provider.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.elasticOut),
      ),
    );

    _controller.repeat(reverse: true, period: const Duration(milliseconds: 1500));

    _checkStartupState();
  }

  Future<void> _checkStartupState() async {
    debugPrint('[SPLASH] _checkStartupState started');
    try {
      // Minimum splash duration + startup decision
      final minSplash = Future.delayed(const Duration(milliseconds: 1500));
      final destinationFuture = ref.read(startupDestinationProvider.future);

      await Future.wait([minSplash, destinationFuture]);
      final destination = await destinationFuture;

      if (!mounted) return;

      debugPrint('[SPLASH] destination: $destination');

      switch (destination) {
        case StartupDestination.home:
          debugPrint('[SPLASH] -> /home');
          await ref.read(authStateProvider.notifier).refreshAuthState();
          if (!mounted) return;
          if (ref.read(authStateProvider).isAuthenticated) {
            context.go('/home');
          } else {
            context.go('/login');
          }
        case StartupDestination.login:
          debugPrint('[SPLASH] -> /login');
          context.go('/login');
        case StartupDestination.onboarding:
          debugPrint('[SPLASH] -> /onboarding');
          context.go('/onboarding');
      }
    } catch (e, st) {
      debugPrint('[SPLASH] ERROR: $e');
      debugPrint('[SPLASH] STACK: $st');
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/images/bsplogo.png',
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.business,
                      size: 80,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Sistem Absensi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            Text(
              'PT Bumi Siak Pusako',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
