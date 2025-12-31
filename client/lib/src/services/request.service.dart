import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/request.dart';
import '../utils/api_client.dart';
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

      // Add files
      for (final file in files) {
        final filename = file.path.split(Platform.pathSeparator).last;
        formData.files.add(
          MapEntry(
            'files',
            MultipartFile.fromFileSync(file.path, filename: filename),
          ),
        );
      }

      final response = await _dio.post(
        ApiEndpoints.createRequest,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
}
