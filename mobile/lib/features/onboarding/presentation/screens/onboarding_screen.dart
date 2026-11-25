import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/app_state_provider.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/features/onboarding/presentation/widgets/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    OnboardingPage(
      icon: Icons.location_on,
      iconColor: AppColors.primary,
      title: 'Sistem Absensi Digital',
      description:
          'PT Bumi Siak Pusako hadirkan solusi absensi modern yang terintegrasi '
          'dengan kamera, GPS, dan deteksi wajah.',
    ),
    OnboardingPage(
      icon: Icons.camera_alt,
      iconColor: AppColors.primary,
      title: 'Absen dengan Scan Wajah',
      description:
          'Absensi hanya dengan satu kali scan wajah + liveness detection '
          '(toleh kiri-kanan). Tidak perlu isi manual, cepat dan akurat.',
    ),
    OnboardingPage(
      icon: Icons.location_on,
      iconColor: AppColors.accent,
      title: 'Validasi Lokasi GPS',
      description:
          'Sistem otomatis memvalidasi lokasi absen Anda berada dalam '
          'radius kantor melalui GPS — tanpa bohongan fake GPS.',
    ),
    OnboardingPage(
      icon: Icons.notifications,
      iconColor: AppColors.info,
      title: 'Notifikasi Real-time',
      description:
          'Dapatkan notifikasi push ketika cuti disetujui, absen butuh persetujuan, '
          'atau ada pengajuan dari tim Anda.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await ref.read(appStateProvider.notifier).completeOnboarding();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.primaryDark,
                    AppColors.darkBackground,
                  ]
                : [
                    AppColors.primary.withValues(alpha: 0.10),
                    theme.colorScheme.surface,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Absensi BSP',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('Lewati'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  physics: const BouncingScrollPhysics(),
                  children: _pages,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  children: [
                    AppButton(
                      text: _currentPage == _pages.length - 1
                          ? 'Mulai Sekarang'
                          : 'Lanjut',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _nextPage,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_currentPage + 1} dari ${_pages.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
