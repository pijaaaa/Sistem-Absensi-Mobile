import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';

/// Widget untuk menampilkan status online / offline / "N menunggu sync"
class OfflineSyncBadge extends ConsumerWidget {
  const OfflineSyncBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCountAsync = ref.watch(pendingCountProvider);

    return pendingCountAsync.when(
      data: (count) {
        if (count == 0) {
          // Tampilkan badge Online / Offline standar jika tidak ada pending queue
          return GestureDetector(
            onTap: () => context.push('/offline-queue'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ContainerDot(color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => context.push('/offline-queue'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.pending.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.pending.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: AppColors.pending, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$count menunggu sync',
                  style: const TextStyle(
                    color: AppColors.pending,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.pending, size: 14),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const SizedBox.shrink(),
    );
  }
}

class ContainerDot extends StatelessWidget {
  final Color color;
  const ContainerDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
