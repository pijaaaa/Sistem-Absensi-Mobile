import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/attendance/data/datasource/attendance_data_source.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:mobile/core/models/attendance_summary_models.dart';

// Monthly summary provider
final monthlySummaryProvider = FutureProvider.family<AttendanceSummaryModel, MonthYearParams>(
  (ref, params) async {
    final dataSource = ref.watch(attendanceDataSourceProvider);
    final response = await dataSource.fetchMonthlySummary(
      year: params.year,
      month: params.month,
    );
    return AttendanceSummaryModel.fromJson(response['data'] ?? response);
  },
);

// Team stats provider (for manager)
final teamStatsProvider = FutureProvider<TeamStatsModel>((ref) async {
  final dataSource = ref.watch(attendanceDataSourceProvider);
  final response = await dataSource.fetchTeamStats();
  return TeamStatsModel.fromJson(response['data'] ?? response);
});

class MonthYearParams {
  final int year;
  final int month;

  MonthYearParams({required this.year, required this.month});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYearParams &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}
