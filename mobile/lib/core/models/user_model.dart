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

  EmployeeModel({
    required this.id,
    required this.nip,
    required this.name,
    this.departmentId,
    this.workLocationId,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
        id: json['id'] as int,
        nip: json['nip'] as String,
        name: json['name'] as String,
        departmentId: json['department_id'] as int?,
        workLocationId: json['work_location_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nip': nip,
        'name': name,
        'department_id': departmentId,
        'work_location_id': workLocationId,
      };
}
