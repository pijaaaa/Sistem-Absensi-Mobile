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
  final int remainingLeave;
  final Map<String, DayStatus> calendar;

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
    required this.remainingLeave,
    required this.calendar,
  });

  static int _toSafeInt(dynamic val, [int fallback = 0]) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is num) return val.toInt();
    return fallback;
  }

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    final calendarRaw = json['calendar'];
    final calendar = <String, DayStatus>{};

    if (calendarRaw is List) {
      for (final item in calendarRaw) {
        if (item is Map<String, dynamic>) {
          final date = item['date'] as String? ?? '';
          if (date.isNotEmpty) {
            calendar[date] = DayStatus.fromJson(item);
          }
        }
      }
    } else if (calendarRaw is Map<String, dynamic>) {
      calendarRaw.forEach((date, data) {
        if (data is Map<String, dynamic>) {
          calendar[date] = DayStatus.fromJson(data);
        }
      });
    }

    final lateData = json['telat'] as Map<String, dynamic>?;
    final lateTotal = _toSafeInt(lateData?['total'] ??
        (lateData?['kuning'] ?? 0) +
            (lateData?['merah'] ?? 0) +
            (lateData?['toleransi'] ?? 0));

    final totalLateTolerance = _toSafeInt(lateData?['toleransi'] ?? lateData?['green'] ?? 0);
    final totalLateYellow = _toSafeInt(lateData?['kuning'] ?? 0);
    final totalLateRed = _toSafeInt(lateData?['merah'] ?? 0);

    return AttendanceSummaryModel(
      year: _toSafeInt(json['year'] ?? DateTime.now().year),
      month: _toSafeInt(json['month'] ?? DateTime.now().month),
      totalPresent: _toSafeInt(
          json['hadir'] ?? json['total_present'] ?? json['total_on_time'] ?? 0),
      totalLate: lateTotal,
      totalOnTime: _toSafeInt(json['tepat_waktu'] ??
          json['total_on_time'] ??
          (_toSafeInt(json['hadir'] ?? 0) - lateTotal)),
      totalLateTolerance: totalLateTolerance,
      totalLateYellow: totalLateYellow,
      totalLateRed: totalLateRed,
      totalMinutesLate: _toSafeInt(
          json['total_menit_telat'] ?? json['total_minutes_late'] ?? 0),
      totalLeave: _toSafeInt(json['cuti'] ?? json['total_leave'] ?? 0),
      totalSick: _toSafeInt(json['sakit'] ?? json['total_sick'] ?? 0),
      totalPermission: _toSafeInt(json['izin'] ?? json['total_permission'] ?? 0),
      totalDinas: _toSafeInt(json['dinas'] ?? json['total_dinas'] ?? 0),
      totalHoliday: _toSafeInt(json['libur'] ?? json['total_holiday'] ?? 0),
      totalAbsent: _toSafeInt(json['alfa'] ?? json['total_absent'] ?? 0),
      remainingLeave: _toSafeInt(json['sisa_cuti'] ?? json['remaining_leave']),
      calendar: calendar,
    );
  }

  DayStatus? get today {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return calendar[dateKey];
  }

  bool get isCheckedInToday {
    final day = today;
    return day != null && day.checkIn != null;
  }

  bool get isCheckedOutToday {
    final day = today;
    return day != null && day.checkOut != null;
  }
}

class DayStatus {
  final String status;
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
      lateMinutes: json['late_minutes'] is int
          ? json['late_minutes'] as int
          : null,
      lateLevel: json['late_level'],
      isDinas: json['is_dinas'] is bool ? json['is_dinas'] as bool : null,
      isOffline: json['is_offline'] is bool ? json['is_offline'] as bool : null,
    );
  }

  bool get isPresent => checkIn != null;
  bool get isCheckedOut => checkOut != null;
  bool get isAbsent => status == 'absent' || status == 'alfa';
  bool get isLate => lateMinutes != null && lateMinutes! > 0;
  bool get isLeave =>
      status == 'leave' ||
      status == 'cuti' ||
      status == 'sakit' ||
      status == 'izin' ||
      status == 'dinas';
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
      totalEmployees:
          json['total_employees'] ?? json['total_karyawan'] ?? 0,
      presentToday: json['present_today'] ?? json['hadir'] ?? 0,
      lateToday: json['late_today'] ?? json['telat'] ?? 0,
      notCheckedIn:
          json['not_checked_in'] ?? json['belum_absen'] ?? 0,
      lateEmployees: (json['late_employees'] as List? ?? [])
          .map((e) => EmployeeAttendance.fromJson(e as Map<String, dynamic>))
          .toList(),
      notCheckedInEmployees:
          (json['not_checked_in_employees'] as List? ?? [])
              .map((e) =>
                  EmployeeAttendance.fromJson(e as Map<String, dynamic>))
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
      lateMinutes: json['late_minutes'] is int
          ? json['late_minutes'] as int
          : null,
      lateLevel: json['late_level'],
    );
  }
}
