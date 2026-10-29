import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/attendance_summary_models.dart';
import 'package:mobile/core/models/leave_models.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:mobile/features/attendance/presentation/providers/summary_providers.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/leave/presentation/providers/leave_providers.dart';

class HomeData {
  final AttendanceSummaryModel? summary;
  final LeaveBalanceModel? leaveBalance;
  final TeamStatsModel? teamStats;
  final int pendingOffline;

  const HomeData({
    this.summary,
    this.leaveBalance,
    this.teamStats,
    required this.pendingOffline,
  });

  HomeData copyWith({
    AttendanceSummaryModel? summary,
    LeaveBalanceModel? leaveBalance,
    TeamStatsModel? teamStats,
    int? pendingOffline,
  }) {
    return HomeData(
      summary: summary ?? this.summary,
      leaveBalance: leaveBalance ?? this.leaveBalance,
      teamStats: teamStats,
      pendingOffline: pendingOffline ?? this.pendingOffline,
    );
  }
}

final todaySummaryProvider = FutureProvider<AttendanceSummaryModel>((ref) {
  final now = DateTime.now();
  return ref.watch(
    monthlySummaryProvider(
      MonthYearParams(year: now.year, month: now.month),
    ).future,
  );
});

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final authState = ref.watch(authStateProvider);
  final isManager = authState.user?.role == 'manager_department';

  AttendanceSummaryModel? summaryModel;
  try {
    final summary = await ref.watch(
      monthlySummaryProvider(
        MonthYearParams(
          year: DateTime.now().year,
          month: DateTime.now().month,
        ),
      ).future,
    );
    summaryModel = summary;
  } catch (_) {}

  LeaveBalanceModel? leaveBalance;
  try {
    leaveBalance = await ref.watch(leaveBalanceProvider.future);
  } catch (_) {}

  TeamStatsModel? teamStats;
  if (isManager) {
    try {
      teamStats = await ref.watch(teamStatsProvider.future);
    } catch (_) {}
  }

  int pendingCount = 0;
  try {
    pendingCount = await ref.watch(pendingCountProvider.future);
  } catch (_) {}

  return HomeData(
    summary: summaryModel,
    leaveBalance: leaveBalance,
    teamStats: teamStats,
    pendingOffline: pendingCount,
  );
});

final todayAttendanceStatusProvider = Provider<String>((ref) {
  final summary = ref.watch(todaySummaryProvider);
  final day = summary.asData?.value.today;

  if (day == null) return 'Belum absen hari ini';
  if (day.isCheckedOut) return 'Sudah pulang';
  if (day.isPresent) {
    if (day.isLate) return 'Telat ${day.lateMinutes ?? 0} menit';
    return 'Sudah masuk';
  }
  if (day.isLeave) return 'Izin/cuti hari ini';
  if (day.isAbsent) return 'Alfa';
  return 'Belum absen hari ini';
});

class RecentActivityItem {
  final String date;
  final String status;
  final String time;
  final StatusType type;
  final bool isCheckedOut;

  const RecentActivityItem({
    required this.date,
    required this.status,
    required this.time,
    required this.type,
    required this.isCheckedOut,
  });
}

final recentActivityProvider = FutureProvider<List<RecentActivityItem>>((ref) async {
  final dataSource = ref.watch(attendanceDataSourceProvider);
  final rawLogs = await dataSource.fetchLogs();

  return rawLogs.map((item) {
    final typeStr = item['type'] ?? 'present';
    StatusType statusType = StatusType.present;
    if (typeStr == 'lateYellow' || typeStr.toString().contains('Telat')) {
      statusType = StatusType.lateYellow;
    }

    return RecentActivityItem(
      date: item['date'] ?? '',
      status: item['status'] ?? 'Hadir',
      time: item['time'] ?? '',
      type: statusType,
      isCheckedOut: item['is_checkout'] ?? false,
    );
  }).toList();
});

final myRequestsProvider = Provider<List<LeaveRequestModel>>((ref) {
  final requestsAsync = ref.watch(leaveRequestsProvider(LeaveRequestsParams()));
  return requestsAsync.asData?.value ?? [];
});
