import 'package:dio/dio.dart';

import '../consts/api_endpoints.dart';
import '../models/attendance_record.dart';
import '../models/schedule.dart';
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

  Future<Schedule?> fetchSchedule() async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      throw AuthException('Please sign in again to view schedule.');
    }

    try {
      final response = await _dio.get(
        ApiEndpoints.schedules,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (data is List && data.isNotEmpty) {
        return Schedule.fromJson(data.first as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch schedule: $e');
    }
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

  Future<List<Map<String, dynamic>>> fetchDailyMonitor(DateTime date) async {
    final token = await _auth.getAccessToken();
    if (token == null) throw AuthException('Not authenticated');

    final response = await _dio.get(
      ApiEndpoints.monitor,
      queryParameters: {'date': date.toIso8601String()},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  }

  Future<void> manualEntry({
    required String userId,
    required DateTime date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? notes,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null) throw AuthException('Not authenticated');

    try {
      await _dio.post(
        ApiEndpoints.manualEntry,
        data: {
          'userId': userId,
          'date': date.toIso8601String().split('T')[0], // yyyy-MM-dd
          if (checkInTime != null) 'checkInTime': checkInTime.toIso8601String(),
          if (checkOutTime != null)
            'checkOutTime': checkOutTime.toIso8601String(),
          if (notes != null) 'notes': notes,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message']);
      }
      throw Exception('Manual entry failed: ${e.message}');
    }
  }
}

