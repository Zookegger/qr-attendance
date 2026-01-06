import 'dart:io';
import 'package:dio/dio.dart';
import '../services/config.service.dart';
import 'auth_interceptor.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final configUrl = ConfigService().baseUrl;
          if (configUrl.isEmpty) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: "Server URL not configured",
                type: DioExceptionType.cancel,
              ),
            );
          }

          options.baseUrl = configUrl;
          return handler.next(options);
        },
      ),
    );

    // Add auth interceptor after basic setup
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Dio get client => _dio;

  /// Parses diverse error formats into a human-readable string.
  /// Handles:
  /// 1. Validation arrays ({ errors: [{ msg: "..." }] })
  /// 2. Simple error objects ({ message: "..." })
  /// 3. HTTP Status Codes (401, 500)
  /// 4. Network timeouts/failures
  String parseErrorMessage(Object error) {
    if (error is DioException) {
      // 1. Try to parse response data (Server provided a specific message)
      if (error.response?.data != null) {
        final data = error.response!.data;

        // A. Handle Validation Array (e.g. express-validator)
        // Format: { "errors": [ { "msg": "Invalid email", "path": "email" } ] }
        if (data is Map<String, dynamic> && data['errors'] is List) {
          final List errors = data['errors'];
          if (errors.isNotEmpty) {
            // Extract messages, deduplicate, and join with newlines
            final messages =
                errors.map((e) {
                  if (e is Map) {
                    return e['msg'] ?? e['message'] ?? e.toString();
                  }
                  return e.toString();
                }).toSet().toList();

            return messages.join('\n');
          }
        }

        // B. Handle Standard JSON Error Objects
        if (data is Map<String, dynamic>) {
          if (data['message'] != null) return data['message'].toString();
          if (data['error'] != null) return data['error'].toString();
        }

        // C. Handle Plain String Responses
        if (data is String && data.isNotEmpty) {
          return data;
        }
      }

      // 2. Fallback to HTTP Status Codes if no body was parsed
      if (error.response?.statusCode != null) {
        switch (error.response!.statusCode) {
          case 400:
            return "Bad Request";
          case 401:
            return "Unauthorized. Please login again.";
          case 403:
            return "Access Denied.";
          case 404:
            return "Resource not found.";
          case 405:
            return "Method not allowed.";
          case 429:
            return "Too many requests. Please try again later.";
          case 500:
            return "Internal Server Error.";
          case 502:
            return "Bad Gateway.";
          case 503:
            return "Service Unavailable.";
        }
      }

      // 3. Handle Network/Dio Specific Types
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Please check your network.";
        case DioExceptionType.connectionError:
          return "No internet connection.";
        case DioExceptionType.cancel:
          return "Request cancelled.";
        case DioExceptionType.badCertificate:
          return "Invalid SSL certificate.";
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return "No internet connection.";
          }
          return "Unexpected error occurred.";
        default:
          return "Something went wrong.";
      }
    }

    // 4. Non-Dio Errors
    return error.toString().replaceAll("Exception:", "").trim();
  }
}