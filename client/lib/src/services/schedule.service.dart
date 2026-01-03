import 'package:dio/dio.dart';
import '../consts/api_endpoints.dart';
import '../utils/api_client.dart';
import '../models/schedule.dart';

class ScheduleService {
  final Dio _dio = ApiClient().client;

  Future<List<Schedule>> searchSchedules({
    String? userId,
    int? shiftId,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _dio.get(
      ApiEndpoints.schedulesSearch,
      queryParameters: {
        if (userId != null) 'user_id': userId,
        if (shiftId != null) 'shift_id': shiftId,
        if (from != null) 'from': from.toIso8601String().split('T')[0],
        if (to != null) 'to': to.toIso8601String().split('T')[0],
      },
    );
    return (res.data as List).map((e) => Schedule.fromJson(e)).toList();
  }

  Future<void> assignSchedule(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.schedules, data: data);
  }

  Future<void> deleteSchedule(int id) async {
    await _dio.delete(ApiEndpoints.scheduleById(id));
  }
}
