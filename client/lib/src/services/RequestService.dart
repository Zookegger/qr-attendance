import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_attendance_frontend/src/utils/api_client.dart';
import '../models/request.dart';
import '../consts/api_endpoints.dart';

class RequestService {
  final Dio _dio = ApiClient().client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getAccessToken() async {
    return _storage.read(key: 'auth_access_token');
  }

  /// CREATE REQUEST (SAFE)
  Future<void> createRequest(Request request, List<File> files) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      final formData = FormData();

      // Add request fields
      request.toJson().forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Add files under the `attachments` field (server expects this)
      for (final file in files) {
        final filename = file.path.split(Platform.pathSeparator).last;
        formData.files.add(
          MapEntry(
            'attachments',
            MultipartFile.fromFileSync(file.path, filename: filename),
          ),
        );
      }

      final response = await _dio.post(
        ApiEndpoints.createRequest,
        data: formData,
      );

      // Debug: print server response
      debugPrint('Create Request Response: ${response.data}');

      // Optional: check the type of the returned data
      if (response.data is Map<String, dynamic>) {
        // Log success or parse further if needed
        debugPrint('Request created successfully.');
      } else {
        debugPrint('Unexpected response type: ${response.data.runtimeType}');
      }
    } on DioException catch (e) {
      final respData = e.response?.data;
      String msg;

      if (respData == null) {
        msg = 'Create request failed';
      } else if (respData is Map) {
        msg = respData['message'] ?? respData['error'] ?? respData.toString();
      } else if (respData is List) {
        // Join list items into a readable string (validation errors, etc.)
        try {
          msg = respData.map((i) => i.toString()).join('; ');
        } catch (_) {
          msg = respData.toString();
        }
      } else {
        // respData might be a plain string or other type
        msg = respData.toString();
      }

      throw Exception(msg);
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
        ApiEndpoints.createRequest,
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
      final resp = await _dio.get('${ApiEndpoints.createRequest}/$id');

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
        '${ApiEndpoints.createRequest}/$id/review',
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
          formData.fields.add(MapEntry(key, value.toString()));
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
        '${ApiEndpoints.createRequest}/${request.id}',
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
      final resp = await _dio.delete('${ApiEndpoints.createRequest}/$id');
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
