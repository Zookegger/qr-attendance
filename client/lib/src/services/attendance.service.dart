import 'package:dio/dio.dart';

import '../consts/api_endpoints.dart';
import '../models/attendance_record.dart';
import 'api/api_client.dart';
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
}
