class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'CITIZEN', 'ROAD_OFFICER', 'STREET_LIGHT_OFFICER', 'TRAFFIC_OFFICER', 'OVERALL_ADMIN'
  final String? departmentCode;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.departmentCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? 'User',
      role: json['role'] ?? 'CITIZEN',
      departmentCode: json['departmentCode'] ?? json['department_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'departmentCode': departmentCode,
    };
  }
}
