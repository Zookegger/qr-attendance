class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? deviceUuid;
  final String? deviceName;
  final String? deviceModel;
  final String? deviceOsVersion;
  final String? position;
  final String? department;
  final String? fcmToken;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.deviceUuid,
    this.deviceName,
    this.deviceModel,
    this.deviceOsVersion,
    this.position,
    this.department,
    this.fcmToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      deviceUuid: json['device_uuid'],
      deviceName: json['device_name'],
      deviceModel: json['device_model'],
      deviceOsVersion: json['device_os_version'],
      position: json['position'],
      department: json['department'],
      fcmToken: json['fcm_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'device_uuid': deviceUuid,
      'device_name': deviceName,
      'device_model': deviceModel,
      'device_os_version': deviceOsVersion,
      'position': position,
      'department': department,
      'fcm_token': fcmToken,
    };
  }
}
