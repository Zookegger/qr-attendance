import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/request.dart';
import '../utils/api_client.dart';
import '../consts/api_endpoints.dart';

class RequestService {
  final Dio _dio = ApiClient().client;

  /// CREATE REQUEST (SAFE) with detailed debug
  Future<void> createRequest(Request request, List<File> files) async {
    try {
      dynamic dataToSend;

      // Nếu có file, dùng FormData
      if (files.isNotEmpty) {
        final formData = FormData();

        // Bắt buộc các field là string
        formData.fields.add(MapEntry('type', request.type.name));
        formData.fields.add(MapEntry('reason', (request.reason ?? '').trim()));
        formData.fields.add(MapEntry('userId', request.userId));

        if (request.fromDate != null)
          formData.fields.add(
            MapEntry('from_date', request.fromDate!.toIso8601String()),
          );
        if (request.toDate != null)
          formData.fields.add(
            MapEntry('to_date', request.toDate!.toIso8601String()),
          );

        formData.fields.add(MapEntry('status', request.status.name));

        // Add files
        for (final file in files) {
          final filename = file.path.split(Platform.pathSeparator).last;
          formData.files.add(
            MapEntry(
              'attachments',
              MultipartFile.fromFileSync(file.path, filename: filename),
            ),
          );
        }

        dataToSend = formData;
      } else {
        // Không có file thì gửi JSON bình thường
        final jsonData = request.toJson();
        dataToSend = jsonData;
      }

      final response = await _dio.post(
        ApiEndpoints.request,
        data: dataToSend,
        options: Options(
          headers: {
            // Nếu gửi FormData, Dio tự set Content-Type
            if (files.isEmpty) 'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('--- Create Request Response ---');
      debugPrint(response.data.toString());
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception(e.message.toString());
    }
  }

  Future<List<Request>> listRequests({
    String? status,
    String? type,
    String? fromDate,
    String? userId,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (status != null) query['status'] = status;
      if (type != null) query['type'] = type;
      if (fromDate != null) query['from_date'] = fromDate;
      if (userId != null) query['user_id'] = userId;

      final resp = await _dio.get(
        ApiEndpoints.request,
        queryParameters: query,
      );

      if (resp.statusCode == null ||
          resp.statusCode! < 200 ||
          resp.statusCode! >= 300) {
        throw Exception(ApiClient().parseErrorMessage(resp));
      }

      final data = resp.data;
      if (data == null ||
          data['requests'] == null ||
          data['requests'] is! List) {
        throw Exception('Invalid response from server');
      }

      final raw = data['requests'] as List;
      return raw.map((e) {
        if (e is Map<String, dynamic>) return Request.fromJson(e);
        return Request.fromJson(Map<String, dynamic>.from(e));
      }).toList();
    } on DioException catch (e) {
      throw Exception(ApiClient().parseErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> getRequest(String id) async {
    try {
      final resp = await _dio.get('${ApiEndpoints.request}/$id');

      if (resp.statusCode == null ||
          resp.statusCode! < 200 ||
          resp.statusCode! >= 300) {
        throw Exception(ApiClient().parseErrorMessage(resp));
      }

      final data = resp.data;
      if (data == null || data['request'] == null || data['request'] is! Map) {
        throw Exception('Invalid response from server');
      }

      return data['request'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(ApiClient().parseErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> reviewRequest(
    String id,
    String status, {
    String? reviewNote,
  }) async {
    try {
      final payload = {'status': status};
      if (reviewNote != null) payload['review_note'] = reviewNote;

      final resp = await _dio.post(
        '${ApiEndpoints.request}/$id/review',
        data: payload,
      );
      if (resp.statusCode == null ||
          resp.statusCode! < 200 ||
          resp.statusCode! >= 300) {
        throw Exception(ApiClient().parseErrorMessage(resp));
      }
    } on DioException catch (e) {
      throw Exception(ApiClient().parseErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updateRequest(Request request, List<File> files) async {
    try {
      if (request.id == null)
        throw Exception('Request id is required for update');

      final formData = FormData();
      request.toJson().forEach((key, value) {
        if (value != null) {
          // Adjust keys to snake_case for backend
          if (key == 'fromDate') {
            formData.fields.add(MapEntry('from_date', value.toString()));
          } else if (key == 'toDate') {
            formData.fields.add(MapEntry('to_date', value.toString()));
          } else if (key == 'userId') {
            formData.fields.add(MapEntry('user_id', value.toString()));
          } else {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        }
      });

      for (final file in files) {
        final filename = file.path.split(Platform.pathSeparator).last;
        formData.files.add(
          MapEntry(
            'attachments',
            MultipartFile.fromFileSync(file.path, filename: filename),
          ),
        );
      }

      final resp = await _dio.put(
        '${ApiEndpoints.request}/${request.id}',
        data: formData,
      );
      if (resp.statusCode == null ||
          resp.statusCode! < 200 ||
          resp.statusCode! >= 300) {
        throw Exception(ApiClient().parseErrorMessage(resp));
      }
    } on DioException catch (e) {
      throw Exception(ApiClient().parseErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> cancelRequest(String id) async {
    try {
      final resp = await _dio.delete('${ApiEndpoints.request}/$id');
      if (resp.statusCode == null ||
          resp.statusCode! < 200 ||
          resp.statusCode! >= 300) {
        throw Exception(ApiClient().parseErrorMessage(resp));
      }
    } on DioException catch (e) {
      throw Exception(ApiClient().parseErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
