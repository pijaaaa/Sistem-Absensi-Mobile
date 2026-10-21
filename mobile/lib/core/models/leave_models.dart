class LeaveRequestModel {
  final int id;
  final String type; // 'cuti', 'sakit', 'izin', 'dinas'
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String? attachmentPath;
  final String? approverName;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? decidedAt;

  LeaveRequestModel({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.attachmentPath,
    this.approverName,
    this.rejectionReason,
    required this.createdAt,
    this.decidedAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'cuti',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      attachmentPath: json['attachment_path'],
      approverName: json['approver_name'],
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      decidedAt: json['decided_at'] != null
          ? DateTime.parse(json['decided_at'])
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get typeLabel {
    switch (type) {
      case 'cuti':
        return 'Cuti Tahunan';
      case 'sakit':
        return 'Sakit';
      case 'izin':
        return 'Izin';
      case 'dinas':
        return 'Dinas';
      default:
        return type;
    }
  }
}

class LeaveBalanceModel {
  final int year;
  final int quota;
  final int used;
  final int remaining;

  LeaveBalanceModel({
    required this.year,
    required this.quota,
    required this.used,
    required this.remaining,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    final quota = json['quota'] ?? 12;
    final used = json['used'] ?? 0;
    return LeaveBalanceModel(
      year: json['year'] ?? DateTime.now().year,
      quota: quota,
      used: used,
      remaining: quota - used,
    );
  }
}
