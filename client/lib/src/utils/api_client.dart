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

  // Helper method to keep your main logic clean
  String parseErrorMessage(Object error) {
    if (error is DioException && error.response?.data != null) {
      final data = error.response!.data;

      // Handle Map (JSON) responses
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message')) return data['message'];
        if (data.containsKey('error')) return data['error'];
      }
      // Handle Plain String responses
      else if (data is String) {
        return data;
      }
    }
    if (error.toString().isNotEmpty) {
      return error.toString();
    }

    // Fallback for timeouts, no internet, etc.
    return 'Something went wrong. Please check your connection.';
  }
}
