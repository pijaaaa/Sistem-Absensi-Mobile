import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/features/notification/presentation/providers/notification_providers.dart';
import 'package:mobile/core/models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationActionProvider.notifier).markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua notifikasi ditandai dibaca')),
                );
              }
            },
              child: const Text('Tandai Semua Dibaca', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          final today = DateTime.now();
          final todayItems = items.where((item) =>
              item.createdAt.year == today.year &&
              item.createdAt.month == today.month &&
              item.createdAt.day == today.day).toList();

          final yesterday = today.subtract(const Duration(days: 1));
          final yesterdayItems = items.where((item) =>
              item.createdAt.year == yesterday.year &&
              item.createdAt.month == yesterday.month &&
              item.createdAt.day == yesterday.day).toList();

          final olderItems = items.where((item) =>
              item.createdAt.isBefore(DateTime(yesterday.year, yesterday.month, yesterday.day))).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (todayItems.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Hari Ini'),
                  ...todayItems.map((item) => _buildNotificationItem(context, ref, item)),
                ],
                if (yesterdayItems.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Kemarin'),
                  ...yesterdayItems.map((item) => _buildNotificationItem(context, ref, item)),
                ],
                if (olderItems.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Lainnya'),
                  ...olderItems.map((item) => _buildNotificationItem(context, ref, item)),
                ],
              ],
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SkeletonLoader(height: 80, borderRadius: BorderRadius.circular(16)),
          ),
        ),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, NotificationModel item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = item.isRead
        ? Colors.transparent
        : (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.08));

    return ListTile(
      tileColor: bgColor,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(Icons.notifications, color: AppColors.primary, size: 20),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
          if (!item.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.info),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(item.body,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            DateFormat('HH:mm • dd MMM yyyy', 'id_ID').format(item.createdAt),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
      onTap: () async {
        if (!item.isRead) {
          await ref.read(notificationActionProvider.notifier).markAsRead(item.id);
        }
      },
    );
  }
}
