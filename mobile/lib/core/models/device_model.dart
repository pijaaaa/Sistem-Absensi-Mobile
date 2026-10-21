class DeviceModel {
  final String deviceUid;
  final String name;
  final String type; // 'primary' or 'backup'
  final String status; // 'active', 'inactive'
  final DateTime? registeredAt;

  DeviceModel({
    required this.deviceUid,
    required this.name,
    required this.type,
    required this.status,
    this.registeredAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceUid: json['device_uid'] ?? '',
      name: json['name'] ?? 'Unknown Device',
      type: json['type'] ?? 'primary',
      status: json['status'] ?? 'active',
      registeredAt: json['registered_at'] != null
          ? DateTime.parse(json['registered_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_uid': deviceUid,
      'name': name,
      'type': type,
      'status': status,
      'registered_at': registeredAt?.toIso8601String(),
    };
  }

  bool get isPrimary => type == 'primary';
  bool get isBackup => type == 'backup';
  bool get isActive => status == 'active';
}
