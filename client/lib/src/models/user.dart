class User {
  final String id;
  final String name;
  final String email;
  final String status;
  final String role;
  final String? deviceUuid;
  final String? deviceName;
  final String? deviceModel;
  final String? deviceOsVersion;
  final String? position;
  final String? department;
  final String? fcmToken;
  final String? dateOfBirth;
  final String? phoneNumber;
  final String? address;
  final String? gender;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.deviceUuid,
    this.deviceName,
    this.deviceModel,
    this.deviceOsVersion,
    this.position,
    this.department,
    this.fcmToken,
    this.dateOfBirth,
    this.phoneNumber,
    this.address,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      status: json['status'] ?? 'UNKNOWN',
      role: json['role'],
      deviceUuid: json['device_uuid'],
      deviceName: json['device_name'],
      deviceModel: json['device_model'],
      deviceOsVersion: json['device_os_version'],
      position: json['position'],
      department: json['department'],
      fcmToken: json['fcm_token'],
      dateOfBirth: json['date_of_birth'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'device_uuid': deviceUuid,
      'device_name': deviceName,
      'device_model': deviceModel,
      'device_os_version': deviceOsVersion,
      'position': position,
      'department': department,
      'fcm_token': fcmToken,
      'date_of_birth': dateOfBirth,
      'phone_number': phoneNumber,
      'address': address,
      'gender': gender,
    };
  }
}
