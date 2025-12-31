import 'package:dio/dio.dart';
import 'package:qr_attendance_frontend/src/consts/api_endpoints.dart';
import '../utils/api_client.dart';

class AdminService {
  final Dio _dio = ApiClient().client;

  Future<void> unbindDevice(String userId) async {
    try {
      await _dio.post(
        ApiEndpoints.unbindDevice,
        data: {'userId': userId},
      );
    } catch (e) {
      rethrow;
    }
  }
}
