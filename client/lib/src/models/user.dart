import 'package:qr_attendance_frontend/src/models/user_device.dart';

enum UserRole {
  ADMIN,
  MANAGER,
  USER;

  static UserRole fromString(String value) {
    final v = value.toUpperCase();
    return UserRole.values.firstWhere(
      (e) => e.name == v,
      orElse: () => UserRole.USER,
    );
  }

  static String toTextString(UserRole value) {
    return value.name[0] + value.name.substring(1).toLowerCase();
  }
}

enum UserStatus {
  ACTIVE,
  INACTIVE,
  PENDING,
  UNKNOWN;

  static UserStatus fromString(String value) {
    final v = value.toUpperCase();
    return UserStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => UserStatus.UNKNOWN,
    );
  }

  static String toTextString(UserStatus value) {
    return value.name[0] + value.name.substring(1).toLowerCase();
  }
}

enum Gender {
  MALE,
  FEMALE,
  OTHER;

  static Gender fromString(String value) {
    final v = value.toUpperCase();
    return Gender.values.firstWhere(
      (e) => e.name == v,
      orElse: () => Gender.OTHER,
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final UserStatus status;
  final UserRole role;
  final String? deviceUuid;
  final String? deviceName;
  final String? deviceModel;
  final String? deviceOsVersion;
  final List<UserDevice>? devices;
  final String? position;
  final String? department;
  final String? fcmToken;
  final DateTime? dateOfBirth;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? phoneNumber;
  final String? address;
  final Gender? gender;

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
    this.devices,
    this.position,
    this.department,
    this.fcmToken,
    this.dateOfBirth,
    this.createdAt,
    this.updatedAt,
    this.phoneNumber,
    this.address,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      status: UserStatus.fromString((json['status'] ?? 'UNKNOWN').toString()),
      role: UserRole.fromString((json['role'] ?? 'USER').toString()),
      deviceUuid: json['device_uuid'],
      deviceName: json['device_name'],
      deviceModel: json['device_model'],
      deviceOsVersion: json['device_os_version'],
      devices: (json['devices'] is List)
          ? (json['devices'] as List)
                .map((e) => UserDevice.fromJson(e as Map<String, dynamic>))
                .toList()
          : (json['user_devices'] is List)
          ? (json['user_devices'] as List)
                .map((e) => UserDevice.fromJson(e as Map<String, dynamic>))
                .toList()
          : (json['device_uuid'] != null)
          ? [
              UserDevice(
                deviceUuid: json['device_uuid'],
                deviceName: json['device_name'],
                deviceModel: json['device_model'],
                deviceOsVersion: json['device_os_version'],
                fcmToken: json['fcm_token'],
              ),
            ]
          : null,
      position: json['position'],
      department: json['department'],
      fcmToken: json['fcm_token'],
      dateOfBirth: json['date_of_birth'] != null
          ? (DateTime.tryParse(json['date_of_birth'].toString())?.toLocal())
          : null,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal())
          : null,
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'].toString())?.toLocal())
          : null,
      phoneNumber: json['phone_number'],
      address: json['address'],
      gender: json['gender'] != null
          ? Gender.fromString(json['gender'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'status': status.name,
      'device_uuid': deviceUuid,
      'device_name': deviceName,
      'device_model': deviceModel,
      'device_os_version': deviceOsVersion,
      'devices': devices?.map((d) => d.toJson()).toList(),
      'position': position,
      'department': department,
      'fcm_token': fcmToken,
      'date_of_birth': dateOfBirth != null
          ? dateOfBirth!.toIso8601String().split('T')[0]
          : null,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'phone_number': phoneNumber,
      'address': address,
      'gender': gender?.name,
    };
  }
}
