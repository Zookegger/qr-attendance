import 'package:dio/dio.dart';
import '../config.service.dart';

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
  }

  Dio get client => _dio;
}
