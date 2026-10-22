class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final EmployeeModel? employee;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employee,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        employee: json['employee'] != null
            ? EmployeeModel.fromJson(json['employee'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (employee != null) 'employee': employee!.toJson(),
      };
}

class EmployeeModel {
  final int id;
  final String nip;
  final String name;
  final int? departmentId;
  final int? workLocationId;
  final WorkLocationModel? workLocation;

  EmployeeModel({
    required this.id,
    required this.nip,
    required this.name,
    this.departmentId,
    this.workLocationId,
    this.workLocation,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
        id: json['id'] as int,
        nip: json['nip'] as String,
        name: json['name'] as String,
        departmentId: json['department_id'] as int?,
        workLocationId: json['work_location_id'] as int?,
        workLocation: json['work_location'] != null
            ? WorkLocationModel.fromJson(json['work_location'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nip': nip,
        'name': name,
        'department_id': departmentId,
        'work_location_id': workLocationId,
        if (workLocation != null) 'work_location': workLocation!.toJson(),
      };
}

class WorkLocationModel {
  final int? id;
  final String? name;
  final String? mode;
  final double? lat;
  final double? lng;
  final int? radiusM;
  final String? polygonJson;

  WorkLocationModel({
    this.id,
    this.name,
    this.mode,
    this.lat,
    this.lng,
    this.radiusM,
    this.polygonJson,
  });

  factory WorkLocationModel.fromJson(Map<String, dynamic> json) {
    final rawLat = json['lat'];
    final rawLng = json['lng'];
    return WorkLocationModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      mode: json['mode'] as String?,
      lat: rawLat == null ? null : (rawLat is int ? (rawLat as int).toDouble() : rawLat as double),
      lng: rawLng == null ? null : (rawLng is int ? (rawLng as int).toDouble() : rawLng as double),
      radiusM: json['radius_m'] as int?,
      polygonJson: json['polygon_json'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode,
        'lat': lat,
        'lng': lng,
        'radius_m': radiusM,
        'polygon_json': polygonJson,
      };
}
