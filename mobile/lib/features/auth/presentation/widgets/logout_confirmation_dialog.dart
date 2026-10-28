import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';

import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

/// Helper function to handle logout with pending offline items warning dialog (Requirement #4)
Future<void> handleLogoutWithOfflineCheck(BuildContext context, WidgetRef ref, VoidCallback onConfirmLogout) async {
  final offlineService = ref.read(offlineAttendanceServiceProvider);
  final authState = ref.read(authStateProvider);
  final userId = authState.user?.id ?? authState.employee?.id ?? 0;
  final pendingCount = await offlineService.getPendingCount(userId);

  if (pendingCount == 0) {
    onConfirmLogout();
    return;
  }

  if (!context.mounted) return;

  // Show warning dialog for pending offline items
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _LogoutPendingDialog(
      pendingCount: pendingCount,
      onSyncFirst: () async {
        Navigator.pop(context);
        // Show sync progress
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        final result = await offlineService.syncPendingAttendances(userId);
        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.success ? AppColors.success : AppColors.error,
            ),
          );

          // Re-check pending count
          final remaining = await offlineService.getPendingCount(userId);
          if (remaining == 0) {
            onConfirmLogout();
          } else {
            // Still has pending (some rejected/failed), ask if they want to logout anyway
            _showForceLogoutDialog(context, remaining, onConfirmLogout);
          }
        }
      },
      onLogoutAnyway: () {
        Navigator.pop(context);
        onConfirmLogout();
      },
    ),
  );
}

void _showForceLogoutDialog(BuildContext context, int count, VoidCallback onConfirmLogout) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Peringatan Keluar'),
      content: Text('Masih ada $count data absensi offline yang gagal/belum tersinkron. Jika Anda keluar sekarang, data mungkin akan hilang jika cache dibersihkan.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirmLogout();
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Tetap Keluar'),
        ),
      ],
    ),
  );
}

class _LogoutPendingDialog extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onSyncFirst;
  final VoidCallback onLogoutAnyway;

  const _LogoutPendingDialog({
    required this.pendingCount,
    required this.onSyncFirst,
    required this.onLogoutAnyway,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Belum Tersinkron'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ada $pendingCount absensi offline yang belum tersinkron ke server.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Disarankan untuk melakukan sinkronisasi terlebih dahulu sebelum keluar dari akun.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onLogoutAnyway,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Keluar Saja'),
        ),
        FilledButton(
          onPressed: onSyncFirst,
          child: const Text('Sync First'),
        ),
      ],
    );
  }
}
