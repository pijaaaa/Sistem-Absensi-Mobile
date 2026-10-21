class AttendanceSummaryModel {
  final int year;
  final int month;
  final int totalPresent;
  final int totalLate;
  final int totalOnTime;
  final int totalLateTolerance;
  final int totalLateYellow;
  final int totalLateRed;
  final int totalMinutesLate;
  final int totalLeave;
  final int totalSick;
  final int totalPermission;
  final int totalDinas;
  final int totalHoliday;
  final int totalAbsent;
  final Map<String, DayStatus> calendar; // date -> status

  AttendanceSummaryModel({
    required this.year,
    required this.month,
    required this.totalPresent,
    required this.totalLate,
    required this.totalOnTime,
    required this.totalLateTolerance,
    required this.totalLateYellow,
    required this.totalLateRed,
    required this.totalMinutesLate,
    required this.totalLeave,
    required this.totalSick,
    required this.totalPermission,
    required this.totalDinas,
    required this.totalHoliday,
    required this.totalAbsent,
    required this.calendar,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    final calendarData = json['calendar'] as Map<String, dynamic>? ?? {};
    final calendar = <String, DayStatus>{};
    
    calendarData.forEach((date, data) {
      if (data is Map<String, dynamic>) {
        calendar[date] = DayStatus.fromJson(data);
      }
    });

    return AttendanceSummaryModel(
      year: json['year'] ?? DateTime.now().year,
      month: json['month'] ?? DateTime.now().month,
      totalPresent: json['total_present'] ?? 0,
      totalLate: json['total_late'] ?? 0,
      totalOnTime: json['total_on_time'] ?? 0,
      totalLateTolerance: json['total_late_tolerance'] ?? 0,
      totalLateYellow: json['total_late_yellow'] ?? 0,
      totalLateRed: json['total_late_red'] ?? 0,
      totalMinutesLate: json['total_minutes_late'] ?? 0,
      totalLeave: json['total_leave'] ?? 0,
      totalSick: json['total_sick'] ?? 0,
      totalPermission: json['total_permission'] ?? 0,
      totalDinas: json['total_dinas'] ?? 0,
      totalHoliday: json['total_holiday'] ?? 0,
      totalAbsent: json['total_absent'] ?? 0,
      calendar: calendar,
    );
  }
}

class DayStatus {
  final String status; // 'present', 'late_tolerance', 'late_yellow', 'late_red', 'leave', 'sick', 'permission', 'dinas', 'holiday', 'absent', 'future'
  final String? checkIn;
  final String? checkOut;
  final int? lateMinutes;
  final String? lateLevel;
  final bool? isDinas;
  final bool? isOffline;

  DayStatus({
    required this.status,
    this.checkIn,
    this.checkOut,
    this.lateMinutes,
    this.lateLevel,
    this.isDinas,
    this.isOffline,
  });

  factory DayStatus.fromJson(Map<String, dynamic> json) {
    return DayStatus(
      status: json['status'] ?? 'future',
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      lateMinutes: json['late_minutes'],
      lateLevel: json['late_level'],
      isDinas: json['is_dinas'],
      isOffline: json['is_offline'],
    );
  }
}

class TeamStatsModel {
  final int totalEmployees;
  final int presentToday;
  final int lateToday;
  final int notCheckedIn;
  final List<EmployeeAttendance> lateEmployees;
  final List<EmployeeAttendance> notCheckedInEmployees;

  TeamStatsModel({
    required this.totalEmployees,
    required this.presentToday,
    required this.lateToday,
    required this.notCheckedIn,
    required this.lateEmployees,
    required this.notCheckedInEmployees,
  });

  factory TeamStatsModel.fromJson(Map<String, dynamic> json) {
    return TeamStatsModel(
      totalEmployees: json['total_employees'] ?? 0,
      presentToday: json['present_today'] ?? 0,
      lateToday: json['late_today'] ?? 0,
      notCheckedIn: json['not_checked_in'] ?? 0,
      lateEmployees: (json['late_employees'] as List? ?? [])
          .map((e) => EmployeeAttendance.fromJson(e as Map<String, dynamic>))
          .toList(),
      notCheckedInEmployees: (json['not_checked_in_employees'] as List? ?? [])
          .map((e) => EmployeeAttendance.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EmployeeAttendance {
  final String name;
  final String? checkIn;
  final int? lateMinutes;
  final String? lateLevel;

  EmployeeAttendance({
    required this.name,
    this.checkIn,
    this.lateMinutes,
    this.lateLevel,
  });

  factory EmployeeAttendance.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendance(
      name: json['name'] ?? 'Unknown',
      checkIn: json['check_in'],
      lateMinutes: json['late_minutes'],
      lateLevel: json['late_level'],
    );
  }
}
