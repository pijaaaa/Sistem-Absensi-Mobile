class TeamAttendanceDetailModel {
  final String date;
  final List<EmployeeAttendanceDetail> employees;

  TeamAttendanceDetailModel({
    required this.date,
    required this.employees,
  });

  factory TeamAttendanceDetailModel.fromJson(Map<String, dynamic> json) {
    return TeamAttendanceDetailModel(
      date: json['date'] as String,
      employees: (json['employees'] as List<dynamic>)
          .map((e) => EmployeeAttendanceDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'employees': employees.map((e) => e.toJson()).toList(),
    };
  }
}

class EmployeeAttendanceDetail {
  final int employeeId;
  final String name;
  final String? checkInAt;
  final String? checkOutAt;
  final double? inLat;
  final double? inLng;
  final double? outLat;
  final double? outLng;
  final String? locationName;
  final bool isBackupDevice;
  final int lateMinutes;
  final String? approvalStatus;

  EmployeeAttendanceDetail({
    required this.employeeId,
    required this.name,
    this.checkInAt,
    this.checkOutAt,
    this.inLat,
    this.inLng,
    this.outLat,
    this.outLng,
    this.locationName,
    required this.isBackupDevice,
    required this.lateMinutes,
    this.approvalStatus,
  });

  factory EmployeeAttendanceDetail.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendanceDetail(
      employeeId: json['employee_id'] as int,
      name: json['name'] as String,
      checkInAt: json['check_in_at'] as String?,
      checkOutAt: json['check_out_at'] as String?,
      inLat: json['in_lat'] as double?,
      inLng: json['in_lng'] as double?,
      outLat: json['out_lat'] as double?,
      outLng: json['out_lng'] as double?,
      locationName: json['location_name'] as String?,
      isBackupDevice: json['is_backup_device'] as bool? ?? false,
      lateMinutes: json['late_minutes'] as int? ?? 0,
      approvalStatus: json['approval_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'name': name,
      'check_in_at': checkInAt,
      'check_out_at': checkOutAt,
      'in_lat': inLat,
      'in_lng': inLng,
      'out_lat': outLat,
      'out_lng': outLng,
      'location_name': locationName,
      'is_backup_device': isBackupDevice,
      'late_minutes': lateMinutes,
      'approval_status': approvalStatus,
    };
  }

  bool get hasCheckedIn => checkInAt != null;
  bool get hasCheckedOut => checkOutAt != null;
  bool get isLate => lateMinutes > 0;
}
