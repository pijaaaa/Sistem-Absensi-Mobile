import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/app_avatar.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/app_progress_ring.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/features/attendance/presentation/providers/summary_providers.dart';

class TeamStatsSection extends ConsumerWidget {
  const TeamStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teamStatsAsync = ref.watch(teamStatsProvider);

    return teamStatsAsync.when(
      data: (stats) {
        final total = stats.totalEmployees;
        final ratio = total == 0 ? 0.0 : stats.presentToday / total;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ringkasan Tim',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Hari ini',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  Row(
                    children: [
                      AppProgressRing(
                        value: ratio,
                        size: 96,
                        strokeWidth: 10,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${stats.presentToday}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'dari $total',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingLG),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hadir hari ini',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                StatusChip(
                                  label: '${stats.lateToday} telat',
                                  type: StatusType.lateYellow,
                                  showDot: false,
                                ),
                                StatusChip(
                                  label: '${stats.notCheckedIn} belum absen',
                                  type: StatusType.holiday,
                                  showDot: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (stats.lateEmployees.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingMD),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Karyawan Telat',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    ...stats.lateEmployees.map(
                      (emp) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            AppAvatar(name: emp.name, size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emp.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Masuk ${emp.checkIn ?? '-'}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              label: '${emp.lateMinutes ?? 0} mnt',
                              type: StatusType.lateYellow,
                              showDot: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => Column(
        children: [
          SkeletonLoader(
            height: 150,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
        ],
      ),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(teamStatsProvider),
      ),
    );
  }
}
