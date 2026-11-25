import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/app_progress_ring.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/home/presentation/providers/home_providers.dart';

class TodayAttendanceCard extends ConsumerWidget {
  final bool isManager;

  const TodayAttendanceCard({
    super.key,
    this.isManager = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(todaySummaryProvider);

    return AppCard(
      child: summaryAsync.when(
        data: (summary) {
          final today = summary.today;
          final recentItems = ref.watch(recentActivityProvider).valueOrNull ?? [];
          final hasCheckedInLog =
              recentItems.any((item) => !item.isCheckedOut);
          final hasCheckedOutLog =
              recentItems.any((item) => item.isCheckedOut);

          final isCheckedIn = summary.isCheckedInToday ||
              (today?.checkIn != null) ||
              hasCheckedInLog;
          final isCheckedOut = summary.isCheckedOutToday ||
              (today?.checkOut != null) ||
              hasCheckedOutLog;

          String statusText = 'Belum absen';
          StatusType statusType = StatusType.pending;

          if (isCheckedOut) {
            statusText = 'Sudah Pulang';
            statusType = StatusType.present;
          } else if (isCheckedIn) {
            if (today?.isLate == true) {
              statusText = 'Telat ${today?.lateMinutes ?? 0} mnt';
              statusType = StatusType.lateYellow;
            } else {
              statusText = 'Sudah Masuk';
              statusType = StatusType.present;
            }
          } else if (today?.isLeave == true) {
            statusText = 'Izin/Cuti';
            statusType = StatusType.leave;
          } else if (today?.isAbsent == true) {
            statusText = 'Alfa';
            statusType = StatusType.absent;
          }

          final authState = ref.watch(authStateProvider);
          final locationName =
              authState.employee?.workLocation?.name ?? 'Lokasi kerja';

          final targetDays = _weekdaysElapsed(DateTime.now());
          final progress =
              targetDays == 0 ? 0.0 : summary.totalPresent / targetDays;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Absen Hari Ini',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  StatusChip(label: statusText, type: statusType),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Jam kerja 08:00 – 17:00',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TimeBlock(
                          label: 'Absen Masuk',
                          value: today?.checkIn,
                          accent: AppColors.primary,
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        _TimeBlock(
                          label: 'Absen Pulang',
                          value: today?.checkOut,
                          accent: AppColors.info,
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                locationName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  AppProgressRing(
                    value: progress,
                    size: 84,
                    strokeWidth: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${summary.totalPresent}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'hadir',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLG),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isCheckedIn
                          ? null
                          : () => context
                              .push('/attendance-flow?isCheckIn=true'),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: Text(isCheckedIn ? 'Sudah Masuk' : 'Masuk'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isCheckedOut
                          ? null
                          : () => context
                              .push('/attendance-flow?isCheckIn=false'),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(isCheckedOut ? 'Sudah Pulang' : 'Pulang'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(height: 24, width: 140),
            const SizedBox(height: 12),
            SkeletonLoader(
              height: 120,
              width: double.infinity,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
          ],
        ),
        error: (e, _) => Text(
          'Gagal memuat status absen',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.error,
          ),
        ),
      ),
    );
  }

  int _weekdaysElapsed(DateTime now) {
    int count = 0;
    for (int day = 1; day <= now.day; day++) {
      final date = DateTime(now.year, now.month, day);
      if (date.weekday != DateTime.saturday &&
          date.weekday != DateTime.sunday) {
        count++;
      }
    }
    return count;
  }
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final String? value;
  final Color accent;

  const _TimeBlock({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value ?? '--:--',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: value == null ? theme.colorScheme.onSurfaceVariant : accent,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
