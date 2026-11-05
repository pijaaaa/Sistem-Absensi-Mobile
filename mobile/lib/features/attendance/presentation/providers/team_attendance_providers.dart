import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/attendance/data/models/team_attendance_detail_model.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';

// State provider untuk tanggal yang dipilih
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// State provider untuk search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider untuk fetch team attendance detail
final teamAttendanceDetailProvider = FutureProvider.autoDispose<TeamAttendanceDetailModel>((ref) async {
  final dataSource = ref.watch(attendanceDataSourceProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  final dateString = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

  final response = await dataSource.fetchTeamAttendanceDetail(
    date: dateString,
    search: searchQuery.isEmpty ? null : searchQuery,
  );

  return TeamAttendanceDetailModel.fromJson(response['data'] ?? response);
});
