import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../consts/api_endpoints.dart';
import '../utils/api_client.dart';

class ReportService {
  ReportService({Dio? dio}) : _dio = dio ?? ApiClient().client;

  final Dio _dio;

  /// Download attendance report as Excel file
  /// Returns the file bytes that can be saved to disk
  Future<Uint8List> downloadAttendanceReport({int? month, int? year}) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;

    final response = await _dio.get(
      ApiEndpoints.adminReport,
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.statusCode == 200 && response.data != null) {
      return Uint8List.fromList(response.data);
    }

    throw Exception('Failed to download report');
  }
}
