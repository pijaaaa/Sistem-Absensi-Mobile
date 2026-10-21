class ApprovalItemModel {
  final int id;
  final String type; // 'leave' or 'attendance'
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  
  // For leave requests
  final String? employeeName;
  final String? leaveType; // 'cuti', 'sakit', 'izin', 'dinas'
  final DateTime? startDate;
  final DateTime? endDate;
  final String? reason;
  
  // For attendance approvals
  final DateTime? attendanceDate;
  final String? checkType; // 'in' or 'out'
  final bool? isBackupDevice;
  
  // Common
  final String? approverName;
  final String? rejectionReason;
  final DateTime? decidedAt;

  ApprovalItemModel({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.employeeName,
    this.leaveType,
    this.startDate,
    this.endDate,
    this.reason,
    this.attendanceDate,
    this.checkType,
    this.isBackupDevice,
    this.approverName,
    this.rejectionReason,
    this.decidedAt,
  });

  factory ApprovalItemModel.fromJson(Map<String, dynamic> json) {
    return ApprovalItemModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'leave',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      employeeName: json['employee_name'],
      leaveType: json['leave_type'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : null,
      reason: json['reason'],
      attendanceDate: json['attendance_date'] != null
          ? DateTime.parse(json['attendance_date'])
          : null,
      checkType: json['check_type'],
      isBackupDevice: json['is_backup_device'],
      approverName: json['approver_name'],
      rejectionReason: json['rejection_reason'],
      decidedAt: json['decided_at'] != null
          ? DateTime.parse(json['decided_at'])
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  
  bool get isLeaveRequest => type == 'leave';
  bool get isAttendanceApproval => type == 'attendance';
}
