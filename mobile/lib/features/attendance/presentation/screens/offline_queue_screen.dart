import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:mobile/features/attendance/presentation/providers/summary_providers.dart';
import 'package:mobile/features/attendance/presentation/screens/offline_history_screen.dart';
import 'package:mobile/features/attendance/data/local/offline_database.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:intl/intl.dart';

class OfflineQueueScreen extends ConsumerStatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  ConsumerState<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends ConsumerState<OfflineQueueScreen> {
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      final service = ref.read(offlineAttendanceServiceProvider);
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id ?? authState.employee?.id ?? 0;
      final result = await service.syncPendingAttendances(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? AppColors.success : AppColors.error,
          ),
        );
        ref.invalidate(offlineQueueProvider);
        ref.invalidate(offlineHistoryProvider);
        ref.invalidate(pendingCountProvider);
        ref.invalidate(pendingOfflineTypesProvider);
        ref.invalidate(monthlySummaryProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queueAsync = ref.watch(offlineQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrean Absensi Offline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Sekarang',
            onPressed: _isSyncing ? null : _syncNow,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: queueAsync.when(
              data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_done_rounded,
                      size: 44,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada antrean offline',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Semua absensi telah tersinkron dengan server',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(offlineQueueProvider);
              ref.invalidate(pendingOfflineTypesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _OfflineItemCard(
                  item: item,
                  onRetry: _isSyncing ? null : _syncNow,
                );
              },
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (_, e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SkeletonLoader(height: 100, borderRadius: BorderRadius.circular(16)),
          ),
        ),
              error: (e, _) => ErrorState(
                message: 'Gagal memuat antrean offline: $e',
                onRetry: () => ref.invalidate(offlineQueueProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final offlineQueueProvider = FutureProvider<List<OfflineAttendance>>((ref) async {
  final db = ref.watch(offlineDatabaseProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id ?? authState.employee?.id ?? 0;
  return await (db.select(db.offlineAttendances)
        ..where((tbl) =>
            tbl.userId.equals(userId) & tbl.isSynced.equals(false))
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
      .get();
});

class _OfflineItemCard extends StatelessWidget {
  final OfflineAttendance item;
  final VoidCallback? onRetry;

  const _OfflineItemCard({required this.item, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCheckIn = item.isCheckIn;
    final isSynced = item.isSynced;
    final hasError =
        !isSynced && item.syncError != null && item.syncError!.isNotEmpty;
    
    // Human-readable status
    String statusLabel;
    StatusType statusType;
    Color statusColor;

    if (isSynced) {
      statusLabel = 'Tersinkron';
      statusType = StatusType.approved;
      statusColor = AppColors.success;
    } else if (hasError && (item.syncError!.contains('Rejected') || item.syncError!.contains('rejected'))) {
      statusLabel = 'Ditolak Server';
      statusType = StatusType.rejected;
      statusColor = AppColors.error;
    } else if (hasError) {
      statusLabel = 'Gagal (Coba lagi)';
      statusType = StatusType.pending;
      statusColor = AppColors.warningYellow;
    } else {
      statusLabel = 'Menunggu Sync';
      statusType = StatusType.pending;
      statusColor = AppColors.pending;
    }

    final formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isCheckIn ? AppColors.success : AppColors.info).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCheckIn ? Icons.login : Icons.logout,
                    color: isCheckIn ? AppColors.success : AppColors.info,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCheckIn ? 'Absen Masuk (Offline)' : 'Absen Pulang (Offline)',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: statusLabel,
                  type: statusType,
                  customColor: statusColor,
                  outline: true,
                ),
              ],
            ),
            if (hasError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.syncError!,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isSynced) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Coba Lagi'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
