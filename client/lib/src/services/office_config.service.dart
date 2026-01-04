import 'package:dio/dio.dart';
import 'package:qr_attendance_frontend/src/consts/api_endpoints.dart';
import 'package:qr_attendance_frontend/src/models/office_config.dart';
import '../utils/api_client.dart';

class OfficeConfigService {
  final Dio _dio = ApiClient().client;

  Future<List<OfficeConfig>> getOfficeConfigs() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminConfig);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => OfficeConfig.fromJson(e)).toList();
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to fetch office configs');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOfficeConfig(Map<String, dynamic> data) async {
    try {
      await _dio.put(ApiEndpoints.adminConfig, data: data);
    } catch (e) {
      rethrow;
    }
  }
}
