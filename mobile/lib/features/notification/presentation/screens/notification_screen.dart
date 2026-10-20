import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final IconData icon;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
    required this.icon,
  });
}

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Dummy data
    final items = [
      NotificationItem(
        id: '1',
        title: 'Pengajuan Disetujui',
        body: 'Cuti tahunan Anda telah disetujui oleh manager.',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        icon: Icons.check_circle,
      ),
      NotificationItem(
        id: '2',
        title: 'Absen dari Device Cadangan',
        body: 'Persetujuan kehadiran device cadangan menunggu persetujuan.',
        time: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
        icon: Icons.warning,
      ),
      NotificationItem(
        id: '3',
        title: 'Pengingat Absen',
        body: 'Jangan lupa absen masuk hari ini.',
        time: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        icon: Icons.notifications,
      ),
    ];

    final todayItems = items.where((item) => item.time.day == DateTime.now().day).toList();
    final yesterdayItems = items.where((item) => item.time.day == DateTime.now().subtract(const Duration(days: 1)).day).toList();
    final olderItems = items.where((item) => item.time.day < DateTime.now().subtract(const Duration(days: 1)).day).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
            },
            child: const Text('Tandai Semua Dibaca', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView(
              children: [
                if (todayItems.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Hari Ini'),
                  ...todayItems.map((item) => _buildNotificationItem(context, item)),
                ],
                if (yesterdayItems.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Kemarin'),
                  ...yesterdayItems.map((item) => _buildNotificationItem(context, item)),
                ],
                if (olderItems.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Lainnya'),
                  ...olderItems.map((item) => _buildNotificationItem(context, item)),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = item.isRead
        ? Colors.transparent
        : (isDark ? const Color(0xFF4FA07C).withOpacity(0.1) : const Color(0xFF2D6049).withOpacity(0.08));

    return ListTile(
      tileColor: bgColor,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Icon(item.icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (!item.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.body,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
          Text(_formatTime(item.time),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
        ],
      ),
      onTap: () {
        // Mark as read and navigate to detail
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}j';
    return '${time.day}/${time.month}';
  }
}
