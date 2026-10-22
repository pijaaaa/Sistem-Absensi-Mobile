import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/gradient_header.dart';
import 'package:mobile/core/models/leave_models.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/core/widgets/stat_tile.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/core/widgets/app_navigation_bar.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/attendance/data/local/offline_attendance_service.dart';
import 'package:mobile/features/attendance/presentation/providers/summary_providers.dart';
import 'package:mobile/features/attendance/presentation/widgets/offline_sync_badge.dart';
import 'package:mobile/features/home/presentation/providers/home_providers.dart';
import 'package:mobile/features/home/presentation/widgets/team_stats_section.dart';
import 'package:mobile/features/home/presentation/widgets/today_attendance_card.dart';
import 'package:mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:mobile/features/notification/presentation/providers/notification_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _greeting(int hour) {
    if (hour < 5) return 'Selamat Malam';
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Sore';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final isManager = authState.user?.role == 'manager_department';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeDataProvider);
          ref.invalidate(todaySummaryProvider);
          ref.invalidate(leaveBalanceProvider);
          if (isManager) ref.invalidate(teamStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            _buildHeader(theme, isDark, authState, isManager),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OfflineSyncBadge(),
                    const SizedBox(height: AppTheme.spacingMD),
                    const TodayAttendanceCard(isManager: true),
                    const SizedBox(height: AppTheme.spacingLG),
                    _buildSummaryStats(context, isManager),
                    const SizedBox(height: AppTheme.spacingLG),
                    if (isManager) ...[
                      const TeamStatsSection(),
                      const SizedBox(height: AppTheme.spacingLG),
                    ],
                    _buildManagerApprovalCard(context),
                    const SizedBox(height: AppTheme.spacingLG),
                    _buildSectionWithTitle(
                      context,
                      'Aktivitas Terakhir',
                      () {},
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    _buildRecentActivity(context),
                    const SizedBox(height: AppTheme.spacingLG),
                    _buildSectionWithTitle(
                      context,
                      'Pengajuan Saya',
                      () {},
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    _buildMyRequests(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppNavigationBar(),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    bool isDark,
    dynamic authState,
    bool isManager,
  ) {
    final hour = _now.hour;
    final greeting = _greeting(hour);
    final userName = authState.user?.name ?? 'Pengguna';
    final department =
        authState.employee?.departmentId != null
            ? 'Department #${authState.employee!.departmentId}'
            : 'PT Bumi Siak Pusako';

    return SliverToBoxAdapter(
      child: GradientHeader(
        height: 200,
        child: SafeArea(
          child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  userName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  department,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_now.day} ${_monthName(_now.month)} ${_now.year}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Builder(
                  builder: (context) {
                    final unreadCount = ref.watch(unreadNotificationsCountProvider);
                    return _NotificationIconButton(unreadCount: unreadCount);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSummaryStats(BuildContext context, bool isManager) {
    return Consumer(
      builder: (context, ref, _) {
        final summaryAsync = ref.watch(todaySummaryProvider);

        return summaryAsync.when(
          data: (summary) {
            final totalPresent = summary.totalPresent;
            final totalLate = summary.totalLate;
            final remainingLeave = summary.remainingLeave;

            return Row(
              children: [
                Expanded(
                  child: StatTile(
                    title: 'Hadir',
                    value: '$totalPresent',
                    icon: Icons.check_circle,
                    iconColor: AppColors.success,
                    onTap: () => context.push('/history'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: StatTile(
                    title: 'Telat',
                    value: '$totalLate',
                    icon: Icons.warning,
                    iconColor: AppColors.warningYellow,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: StatTile(
                    title: 'Sisa Cuti',
                    value: '$remainingLeave',
                    icon: Icons.calendar_today,
                    iconColor: AppColors.info,
                    onTap: () => context.push('/leave'),
                  ),
                ),
              ],
            );
          },
          loading: () => Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: SkeletonLoader(
                    height: 80,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          error: (e, _) => StatTile(
              title: 'Gagal memuat',
              value: '0',
              icon: Icons.error,
              iconColor: AppColors.error,
            ),
        );
      },
    );
  }

  Widget _buildManagerApprovalCard(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final authState = ref.watch(authStateProvider);
        final isManager = authState.user?.role == 'manager_department';
        if (!isManager) return const SizedBox.shrink();

        return ref.watch(todaySummaryProvider).when(
          data: (_) => Card(
              child: InkWell(
                onTap: () => context.push('/approval'),
                borderRadius: BorderRadius.circular(20),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '3 pengajuan menunggu persetujuan',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          loading: () => SkeletonLoader(
              height: 60,
              borderRadius: BorderRadius.circular(20),
            ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final items = ref.watch(recentActivityProvider);
        if (items.isEmpty) {
          return const Center(
            child: Text('Belum ada aktivitas absensi.'),
          );
        }
        return Column(
          children:
              items.asMap().entries.map((entry) {
                final item = entry.value;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Icon(
                      Icons.history,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(item.status),
                  subtitle:
                      Text('${item.date} • ${item.time}'),
                  trailing: StatusChip(
                    label: item.status,
                    type: item.type,
                    outline: true,
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildMyRequests(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final items = ref.watch(myRequestsProvider);
        if (items.isEmpty) {
          return const Center(
            child: Text('Belum ada pengajuan cuti.'),
          );
        }
        return Column(
          children:
              items.take(5).toList().asMap().entries.map((entry) {
                final req = entry.value;
                return ListTile(
                  leading: Icon(
                    Icons.document_scanner_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(req.typeLabel),
                  subtitle: Text(
                    '${req.startDate.day}/${req.startDate.month}/${req.startDate.year} - ${req.endDate.day}/${req.endDate.month}/${req.endDate.year}',
                  ),
                  trailing: StatusChip(
                    label: _statusLabel(req),
                    type: _statusType(req),
                    outline: true,
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  String _statusLabel(LeaveRequestModel req) {
    switch (req.status) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Pending';
    }
  }

  StatusType _statusType(LeaveRequestModel req) {
    switch (req.status) {
      case 'approved':
        return StatusType.approved;
      case 'rejected':
        return StatusType.rejected;
      default:
        return StatusType.pending;
    }
  }

  Widget _buildSectionWithTitle(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            'Lihat Semua',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationIconButton extends StatelessWidget {
  final int unreadCount;

  const _NotificationIconButton({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/notifications'),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          width: 36,
          height: 36,
          child: Stack(
            children: [
              const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 18,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
