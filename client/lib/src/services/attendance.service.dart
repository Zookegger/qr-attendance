import 'package:dio/dio.dart';

import '../consts/api_endpoints.dart';
import '../models/attendance_record.dart';
import '../utils/api_client.dart';
import 'auth.service.dart';

class AttendanceService {
  AttendanceService({Dio? dio, AuthenticationService? auth})
      : _dio = dio ?? ApiClient().client,
        _auth = auth ?? AuthenticationService();

  final Dio _dio;
  final AuthenticationService _auth;

  Future<List<AttendanceRecord>> fetchHistory({required DateTime month}) async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      throw AuthException('Please sign in again to view history.');
    }

    final response = await _dio.get(
      ApiEndpoints.history,
      queryParameters: {
        'month': month.month,
        'year': month.year,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(AttendanceRecord.fromJson)
          .toList();
    }

    throw AuthException('Invalid history data received.');
  }

  Future<void> checkIn({
    required String code,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null) throw AuthException('Not authenticated');

    try {
      await _dio.post(
        ApiEndpoints.checkIn,
        data: {
          'code': code,
          'latitude': latitude,
          'longitude': longitude,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message']);
      }
      throw Exception('Check-in failed: ${e.message}');
    }
  }

  Future<void> checkOut({
    required String code,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null) throw AuthException('Not authenticated');

    try {
      await _dio.post(
        ApiEndpoints.checkOut,
        data: {
          'code': code,
          'latitude': latitude,
          'longitude': longitude,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message']);
      }
      throw Exception('Check-out failed: ${e.message}');
    }
  }
}
