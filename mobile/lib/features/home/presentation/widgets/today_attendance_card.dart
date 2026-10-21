import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/features/home/presentation/providers/home_providers.dart';

class TodayAttendanceCard extends ConsumerWidget {
  final bool isManager;

  const TodayAttendanceCard({
    super.key,
    this.isManager = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildStatus(context, ref),
          const SizedBox(height: 20),
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    const dateStr = '19 Oktober 2026';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Absen Hari Ini',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          dateStr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatus(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(todaySummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        final today = summary.today;
        final isCheckedIn = summary.isCheckedInToday;
        final isCheckedOut = summary.isCheckedOutToday;

        String statusText = 'Belum absen hari ini';
        StatusType statusType = StatusType.pending;

        if (isCheckedOut) {
          statusText = 'Sudah Pulang';
          statusType = StatusType.present;
        } else if (isCheckedIn) {
          if (today?.isLate == true) {
            statusText = 'Telat ${today?.lateMinutes ?? 0} menit';
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              label: statusText,
              type: statusType,
            ),
            const SizedBox(height: 12),
            _buildScheduleInfo(context, today),
          ],
        );
      },
      loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(height: 24, width: 120),
            const SizedBox(height: 12),
            SkeletonLoader(
              height: 16,
              width: double.infinity,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      error: (e, _) => Text(
          'Gagal memuat status absen',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.error,
          ),
        ),
    );
  }

  Widget _buildScheduleInfo(BuildContext context, dynamic today) {
    final theme = Theme.of(context);
    final checkIn = today?.checkIn;
    final checkOut = today?.checkOut;

    if (checkIn == null && checkOut == null) {
      return Text(
        'Jadwal: 08:00 - 17:00',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      children: [
        if (checkIn != null)
          _buildTimeInfo(context, 'Masuk', checkIn, AppColors.success),
        if (checkIn != null && checkOut != null)
          const SizedBox(width: 24),
        if (checkOut != null)
          _buildTimeInfo(context, 'Pulang', checkOut, AppColors.info),
      ],
    );
  }

  Widget _buildTimeInfo(
    BuildContext context,
    String label,
    String time,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label $time',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(todaySummaryProvider);
    final hasCheckedIn = summaryAsync.valueOrNull?.isCheckedInToday ?? false;
    final hasCheckedOut = summaryAsync.valueOrNull?.isCheckedOutToday ?? false;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: (hasCheckedIn && !hasCheckedOut)
                ? () => context.push('/attendance-flow?isCheckIn=false')
                : (hasCheckedIn && hasCheckedOut)
                    ? null
                    : () => context.push('/attendance-flow?isCheckIn=true'),
            icon: Icon(
              hasCheckedIn
                  ? (hasCheckedOut
                      ? Icons.login
                      : Icons.logout)
                  : Icons.login,
              size: 18,
            ),
            label: Text(
              hasCheckedOut
                  ? 'Sudah Pulang'
                  : hasCheckedIn
                      ? 'Pulang'
                      : 'Masuk',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history, size: 16),
            label: const Text('Riwayat'),
          ),
        ),
      ],
    );
  }
}
