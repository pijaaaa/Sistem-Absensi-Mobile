import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/app_avatar.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/gradient_header.dart';
import 'package:mobile/core/models/leave_models.dart';
import 'package:mobile/core/widgets/section_header.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/core/widgets/stat_tile.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/core/widgets/app_navigation_bar.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/core/providers/app_state_provider.dart';
import 'package:mobile/core/services/push_notification_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPushCallbacks();
      _refreshData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData();
  }

  void _refreshData() {
    final now = DateTime.now();
    ref.invalidate(todaySummaryProvider);
    ref.invalidate(monthlySummaryProvider(MonthYearParams(year: now.year, month: now.month)));
    ref.invalidate(homeDataProvider);
    ref.invalidate(recentActivityProvider);
  }

  Future<void> _setupPushCallbacks() async {
    final isLoggedIn = ref.read(appStateProvider).isLoggedIn;
    if (!mounted || !isLoggedIn) return;

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty && mounted) {
        await ref.read(authDataSourceProvider).updateFcmToken(fcmToken);
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString(StorageKeys.fcmToken, fcmToken);
      }
    } catch (e) {
      debugPrint('[HOME] Gagal register FCM token: $e');
    }

    if (!mounted) return;
    // Minta izin notifikasi Android 13+
    await PushNotificationService.instance.requestPermission(context);

    // Callback lifecycle (service tidak butuh context/ref).
    PushNotificationService.isAuthorized = () => ref.read(appStateProvider).isLoggedIn;
    PushNotificationService.onTokenRefreshed = (token) {
      ref.read(authDataSourceProvider).updateFcmToken(token);
    };
    AppStateNotifier.onLogout ??= () => ref.read(authRepositoryProvider).logout();

    final pending = PushNotificationService.consumePendingNavigation();
    if (pending != null && mounted) {
      GoRouter.maybeOf(context)?.go(pending.route);
    }
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
    final homeInitAsync = ref.watch(homeInitProvider);

    return Scaffold(
      body: homeInitAsync.when(
        data: (_) => RefreshIndicator(
          onRefresh: () async {
            final now = DateTime.now();
            ref.invalidate(homeInitProvider);
            ref.invalidate(homeDataProvider);
            ref.invalidate(todaySummaryProvider);
            ref.invalidate(monthlySummaryProvider(MonthYearParams(year: now.year, month: now.month)));
            ref.invalidate(recentActivityProvider);
            ref.invalidate(leaveBalanceProvider);
            if (isManager) ref.invalidate(teamStatsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildHeader(theme, isDark, authState, isManager),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMD,
                    AppTheme.spacingMD,
                    AppTheme.spacingMD,
                    AppTheme.spacingXL,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const OfflineSyncBadge(),
                      const SizedBox(height: AppTheme.spacingMD),
                      TodayAttendanceCard(isManager: isManager),
                      const SizedBox(height: AppTheme.spacingLG),
                      _buildSummaryStats(context, isManager),
                      const SizedBox(height: AppTheme.spacingLG),
                      if (isManager) ...[
                        const TeamStatsSection(),
                        const SizedBox(height: AppTheme.spacingLG),
                        _buildMonitoringCard(context),
                        const SizedBox(height: AppTheme.spacingLG),
                      ],
                      _buildManagerApprovalCard(context),
                      const SizedBox(height: AppTheme.spacingLG),
                      SectionHeader(
                        title: 'Aktivitas Terakhir',
                        actionLabel: 'Lihat Semua',
                        onAction: () => context.push('/history'),
                      ),
                      const SizedBox(height: AppTheme.spacingSM),
                      _buildRecentActivity(context),
                      const SizedBox(height: AppTheme.spacingLG),
                      SectionHeader(
                        title: 'Pengajuan Saya',
                        actionLabel: 'Lihat Semua',
                        onAction: () => context.push('/leave'),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Gagal memuat data home. Silakan coba lagi.',
          onRetry: () => ref.invalidate(homeInitProvider),
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
        height: 212,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(
                    name: userName,
                    size: 44,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        Text(
                          userName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          department,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _NotificationIconButton(
                    unreadCount: ref.watch(unreadNotificationsCountProvider),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_now.day} ${_monthName(_now.month)} ${_now.year}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')} WIB',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    icon: Icons.warning_amber_rounded,
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
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == 2 ? 0 : AppTheme.spacingSM,
                    ),
                    child: SkeletonLoader(
                      height: 120,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    ),
                  ),
                ),
              ),
            ),
          error: (e, _) => AppCard(
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gagal memuat ringkasan kehadiran',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
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
          data: (_) => AppCard(
            onTap: () => context.push('/approval'),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fact_check_outlined,
                    color: AppColors.warningYellow,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approval',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pengajuan menunggu keputusan Anda',
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
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
          loading: () => SkeletonLoader(
              height: 80,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final recentAsync = ref.watch(recentActivityProvider);

        return recentAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return AppCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    const Text('Belum ada aktivitas absensi.'),
                  ],
                ),
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isLast = entry.key == items.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.isCheckedOut
                                    ? Icons.logout_rounded
                                    : Icons.login_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.status,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.date} • ${item.time}',
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
                            ),
                            StatusChip(
                              label: item.status,
                              type: item.type,
                              outline: true,
                              showDot: false,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: AppTheme.spacingMD,
                          endIndent: AppTheme.spacingMD,
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.5),
                        ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
          loading: () => SkeletonLoader(
            height: 160,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          error: (error, stack) => AppCard(
            child: const Text('Gagal memuat aktivitas.'),
          ),
        );
      },
    );
  }

  Widget _buildMyRequests(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final items = ref.watch(myRequestsProvider);
        if (items.isEmpty) {
          return AppCard(
            child: Row(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                const Text('Belum ada pengajuan cuti.'),
              ],
            ),
          );
        }
        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children:
                items.take(5).toList().asMap().entries.map((entry) {
              final req = entry.value;
              final isLast = entry.key == items.take(5).length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.typeLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${req.startDate.day}/${req.startDate.month}/${req.startDate.year} - ${req.endDate.day}/${req.endDate.month}/${req.endDate.year}',
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
                        ),
                        StatusChip(
                          label: _statusLabel(req),
                          type: _statusType(req),
                          showDot: false,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: AppTheme.spacingMD,
                      endIndent: AppTheme.spacingMD,
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    ),
                ],
              );
            }).toList(),
          ),
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

  Widget _buildMonitoringCard(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => context.push('/team-attendance-monitoring'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monitoring Kehadiran',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lihat detail kehadiran karyawan',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
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
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 20,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
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
