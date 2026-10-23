import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';

/// Widget untuk menampilkan status offline sync
class OfflineSyncBadge extends ConsumerWidget {
  const OfflineSyncBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCountAsync = ref.watch(pendingCountProvider);

    return pendingCountAsync.when(
      data: (count) {
        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.pending,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Offline: $count menunggu sync',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Dialog untuk trigger manual sync
class ManualSyncDialog extends ConsumerStatefulWidget {
  const ManualSyncDialog({super.key});

  @override
  ConsumerState<ManualSyncDialog> createState() => _ManualSyncDialogState();
}

class _ManualSyncDialogState extends ConsumerState<ManualSyncDialog> {
  bool _isSyncing = false;
  String? _message;

  Future<void> _syncNow() async {
    setState(() {
      _isSyncing = true;
      _message = null;
    });

    try {
      final offlineService = ref.read(offlineAttendanceServiceProvider);
      final result = await offlineService.syncPendingAttendances();

      if (mounted) {
        setState(() {
          _isSyncing = false;
          _message = result.message;
        });

        if (result.success) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _message = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingCountAsync = ref.watch(pendingCountProvider);

    return AlertDialog(
      title: const Text('Sync Data Offline'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSyncing)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Sedang sync...'),
              ],
            )
          else ...[
            pendingCountAsync.when(
              data: (count) => Text(
                count > 0
                    ? 'Ada $count absensi offline yang belum tersinkron. Sync sekarang?'
                    : 'Tidak ada data offline yang perlu disync.',
                textAlign: TextAlign.center,
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading data'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: theme.textTheme.bodySmall?.copyWith(
                   color: _message!.contains('Error')
                      ? AppColors.error
                      : AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
      actions: [
        if (!_isSyncing) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          pendingCountAsync.when(
            data: (count) => count > 0
                ? FilledButton(
                    onPressed: _syncNow,
                    child: const Text('Sync Sekarang'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
