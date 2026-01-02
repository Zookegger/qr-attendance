import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserDeviceService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserDeviceService(this._dio);

  Future<void> registerDevice({
    required String deviceUuid,
    String? deviceName,
    String? deviceModel,
    String? deviceOsVersion,
    String? fcmToken,
  }) async {
    final accessToken = await _storage.read(key: 'accessToken');
    if (accessToken == null) throw Exception('AccessToken not found');

    await _dio.post(
      '/user_devices',
      data: {
        "device_uuid": deviceUuid,
        "device_name": deviceName,
        "device_model": deviceModel,
        "device_os_version": deviceOsVersion,
        "fcm_token": fcmToken,
      },
      options: Options(headers: {"Authorization": "Bearer $accessToken"}),
    );
  }
}
