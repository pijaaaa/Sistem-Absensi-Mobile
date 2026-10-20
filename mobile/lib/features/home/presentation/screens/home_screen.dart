import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/stat_tile.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/attendance/presentation/widgets/offline_sync_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final isManager = authState.user?.role == 'manager_department';
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 5
        ? 'Selamat Malam'
        : hour < 11
            ? 'Selamat Pagi'
            : hour < 17
                ? 'Selamat Siang'
                : 'Selamat Sore';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient Header
          SliverAppBar(
            pinned: false,
            expandedHeight: 220,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            AppColors.primaryDark,
                            AppColors.primary,
                          ]
                        : [
                            AppColors.primaryDark,
                            AppColors.primary,
                          ],
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        greeting,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        authState.user?.name ?? 'Pengguna',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authState.employee?.departmentId != null
                            ? 'Department #${authState.employee!.departmentId}'
                            : 'PT Bumi Siak Pusako',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${now.day} ${_monthName(now.month)} ${now.year}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            '${_formatTime(now.hour, now.minute)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Offline Sync Badge
                  const OfflineSyncBadge(),
                  const SizedBox(height: 12),
                  
                  // Attendance Card
                  _AttendanceCard(isManager: isManager),
                  const SizedBox(height: 24),

                  // Summary Stats
                  _buildSummaryStats(context, isManager),
                  const SizedBox(height: 24),

                  // Today's Summary Section Title
                  if (isManager) ...[
                    _buildManagerCard(context),
                    const SizedBox(height: 24),
                  ],

                  // Recent Activity
                  _buildSectionTitle(context, 'Aktivitas Terakhir'),
                  const SizedBox(height: 12),
                  _buildRecentActivity(context, isManager),
                  const SizedBox(height: 24),

                  // My Requests
                  _buildSectionTitle(context, 'Pengajuan Saya'),
                  const SizedBox(height: 12),
                  _buildMyRequests(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, bool isManager) {
    return Row(
      children: [
        Expanded(
          child: StatTile(
            title: 'Hadir',
            value: '18',
            icon: Icons.check_circle,
            iconColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            title: 'Telat',
            value: '2',
            icon: Icons.warning,
            iconColor: AppColors.warningYellow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            title: 'Sisa Cuti',
            value: '8',
            icon: Icons.calendar_today,
            iconColor: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildManagerCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perlu Persetujuan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '3 pengajuan menunggu persetujuan',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, bool isManager) {
    final items = [
      {'date': '19 Okt', 'status': 'Hadir', 'time': '08:02', 'type': StatusType.present},
      {'date': '18 Okt', 'status': 'Telat 5m', 'time': '08:15', 'type': StatusType.tolerance},
      {'date': '17 Okt', 'status': 'Pulang', 'time': '17:00', 'type': StatusType.present},
    ];

    return Column(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        final statusType = item['type'] as StatusType;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                AppColors.primary.withOpacity(0.15),
            child: Icon(
              Icons.history,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text('${item['status']}'),
          subtitle: Text('${item['date']} • ${item['time']}'),
          trailing: StatusChip(
            label: item['status'] as String? ?? 'Status',
            type: statusType,
            outline: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMyRequests(BuildContext context) {
    final items = [
      {'title': 'Cuti Tahunan', 'date': '01-15 Okt 2026', 'status': 'Disetujui', 'type': StatusType.approved},
      {'title': 'Izin Sakit', 'date': '10 Okt 2026', 'status': 'Pending', 'type': StatusType.pending},
    ];

    return Column(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        final statusType = item['type'] as StatusType;
        return ListTile(
          leading: Icon(
            Icons.document_scanner_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(item['title'] as String? ?? ''),
          subtitle: Text(item['date'] as String? ?? ''),
          trailing: StatusChip(
            label: item['status'] as String? ?? 'Status',
            type: statusType,
            outline: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Lihat Semua',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _monthName(int month) {
  const months = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return months[month];
}

String _formatTime(int hour, int minute) {
  final h = hour.toString().padLeft(2, '0');
  final m = minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// Attendance Card
class _AttendanceCard extends ConsumerWidget {
  final bool isManager;

  const _AttendanceCard({required this.isManager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Absen Hari Ini',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '19 Oktober 2026',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum absen hari ini',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push('/attendance-flow?isCheckIn=true');
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Masuk'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push('/attendance-flow?isCheckIn=false');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Pulang'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
