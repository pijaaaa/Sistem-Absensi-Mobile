import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:mobile/features/attendance/data/local/offline_database.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:intl/intl.dart';

class OfflineHistoryScreen extends ConsumerStatefulWidget {
  const OfflineHistoryScreen({super.key});

  @override
  ConsumerState<OfflineHistoryScreen> createState() => _OfflineHistoryScreenState();
}

class _OfflineHistoryScreenState extends ConsumerState<OfflineHistoryScreen> {
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
        ref.invalidate(offlineHistoryProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal sinkronisasi: $e'),
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
    final historyAsync = ref.watch(offlineHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrean & Riwayat Offline'),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sinkronisasi Sekarang',
              onPressed: _syncNow,
            ),
        ],
      ),
      body: historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_done,
                    size: 80,
                    color: AppColors.success.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Semua Tersinkron',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada antrean absensi offline',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Separate pending and synced items
          final pendingItems = items.where((item) => !item.isSynced).toList();
          final syncedItems = items.where((item) => item.isSynced).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(offlineHistoryProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pendingItems.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Menunggu Sinkronisasi',
                    pendingItems.length,
                    AppColors.warningYellow,
                  ),
                  const SizedBox(height: 12),
                  ...pendingItems.map((item) => _OfflineHistoryItemCard(
                        item: item,
                        onRetry: _isSyncing ? null : _syncNow,
                      )),
                  const SizedBox(height: 24),
                ],
                if (syncedItems.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Tersinkron',
                    syncedItems.length,
                    AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  ...syncedItems.map((item) => _OfflineHistoryItemCard(item: item)),
                ],
              ],
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SkeletonLoader(
              height: 120,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        error: (error, _) => ErrorState(
          message: 'Gagal memuat riwayat offline: $error',
          onRetry: () => ref.invalidate(offlineHistoryProvider),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

final offlineHistoryProvider = FutureProvider<List<OfflineAttendance>>((ref) async {
  final db = ref.watch(offlineDatabaseProvider);
  return await (db.select(db.offlineAttendances)
        ..orderBy([
          (tbl) => OrderingTerm(expression: tbl.isSynced),
          (tbl) => OrderingTerm.desc(tbl.createdAt),
        ]))
      .get();
});

class _OfflineHistoryItemCard extends StatelessWidget {
  final OfflineAttendance item;
  final VoidCallback? onRetry;

  const _OfflineHistoryItemCard({
    required this.item,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCheckIn = item.isCheckIn;
    final isSynced = item.isSynced;
    final hasError = item.syncError != null && item.syncError!.isNotEmpty;

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
      statusLabel = 'Gagal Sync';
      statusType = StatusType.pending;
      statusColor = AppColors.warningYellow;
    } else {
      statusLabel = 'Menunggu';
      statusType = StatusType.pending;
      statusColor = AppColors.pending;
    }

    final formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(item.createdAt);
    final formattedTime = DateFormat('HH:mm:ss', 'id_ID').format(item.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isCheckIn ? AppColors.success : AppColors.info).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCheckIn ? Icons.login : Icons.logout,
                    color: isCheckIn ? AppColors.success : AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCheckIn ? 'Absen Masuk (Offline)' : 'Absen Pulang (Offline)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          Text(
                            formattedTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.syncError!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isSynced && onRetry != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Coba Lagi'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
