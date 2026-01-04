class UserDevice {
  final int? id;
  final String? userId;
  final String deviceUuid;
  final String? deviceName;
  final String? deviceModel;
  final String? deviceOsVersion;
  final String? fcmToken;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserDevice({
    this.id,
    this.userId,
    required this.deviceUuid,
    this.deviceName,
    this.deviceModel,
    this.deviceOsVersion,
    this.fcmToken,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      userId: json['user_id']?.toString(),
      deviceUuid: json['device_uuid'] ?? json['deviceUuid'] ?? '',
      deviceName: json['device_name'] ?? json['deviceName'],
      deviceModel: json['device_model'] ?? json['deviceModel'],
      deviceOsVersion: json['device_os_version'] ?? json['deviceOsVersion'],
      fcmToken: json['fcm_token'] ?? json['fcmToken'],
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'].toString())?.toLocal()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_uuid': deviceUuid,
      'device_name': deviceName,
      'device_model': deviceModel,
      'device_os_version': deviceOsVersion,
      'fcm_token': fcmToken,
      'last_login': lastLogin?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
