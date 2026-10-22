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

final recentActivityProvider = Provider<List<RecentActivityItem>>((ref) {
  final summaryAsync = ref.watch(todaySummaryProvider);
  final calendar = summaryAsync.asData?.value.calendar;
  if (calendar == null) return [];

  final sortedDates = calendar.keys.toList()..sort((a, b) => b.compareTo(a));
  final items = <RecentActivityItem>[];

  for (final date in sortedDates) {
    if (items.length >= 5) break;
    final day = calendar[date];
    if (day == null || day.checkIn == null) continue;

    final parsed = DateTime.tryParse(date);
    final formattedDate = parsed != null
        ? '${parsed.day} ${_monthName(parsed.month)}'
        : date;

    final checkInTime = day.checkIn ?? '';
    final checkOutTime = day.checkOut;
    final isLate = day.isLate;
    final status = isLate
        ? 'Telat ${day.lateMinutes ?? 0}m'
        : (checkOutTime != null ? 'Pulang' : 'Hadir');

    items.add(RecentActivityItem(
      date: formattedDate,
      status: status,
      time: checkOutTime ?? checkInTime,
      type: checkOutTime != null
          ? StatusType.present
          : (isLate ? StatusType.lateYellow : StatusType.present),
      isCheckedOut: checkOutTime != null,
    ));

    if (checkOutTime != null && checkInTime.isNotEmpty) {
      final checkoutItem = RecentActivityItem(
        date: formattedDate,
        status: 'Pulang',
        time: checkOutTime,
        type: StatusType.present,
        isCheckedOut: true,
      );
      if (items.length < 5) items.add(checkoutItem);
    }
  }
  return items;
});

String _monthName(int month) {
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return months[month] ?? '';
}

final myRequestsProvider = Provider<List<LeaveRequestModel>>((ref) {
  final requestsAsync = ref.watch(leaveRequestsProvider(LeaveRequestsParams()));
  return requestsAsync.asData?.value ?? [];
});
