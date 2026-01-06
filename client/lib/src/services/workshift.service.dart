import 'package:dio/dio.dart';
import '../consts/api_endpoints.dart';
import '../utils/api_client.dart';
import '../models/workshift.dart';

class WorkshiftService {
  final Dio _dio = ApiClient().client;

  Future<List<Workshift>> listWorkshifts() async {
    final res = await _dio.get(ApiEndpoints.workshifts);
    return (res.data as List).map((e) => Workshift.fromJson(e)).toList();
  }

  Future<void> createWorkshift(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.workshifts, data: data);
  }

  Future<void> updateWorkshift(int id, Map<String, dynamic> data) async {
    await _dio.put(ApiEndpoints.workshiftById(id), data: data);
  }

  Future<void> deleteWorkshift(int id) async {
    await _dio.delete(ApiEndpoints.workshiftById(id));
  }
}
