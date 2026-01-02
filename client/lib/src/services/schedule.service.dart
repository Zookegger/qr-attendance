import 'package:dio/dio.dart';
import '../consts/api_endpoints.dart';
import '../utils/api_client.dart';
import '../models/schedule.dart';

class ScheduleService {
  final Dio _dio = ApiClient().client;

  Future<List<Schedule>> searchSchedules({String? userId, int? shiftId}) async {
    final res = await _dio.get(
      ApiEndpoints.schedulesSearch,
      queryParameters: {
        if (userId != null) 'user_id': userId,
        if (shiftId != null) 'shift_id': shiftId,
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
