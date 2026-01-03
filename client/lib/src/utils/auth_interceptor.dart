import 'dart:async';
import 'package:dio/dio.dart';
import 'package:qr_attendance_frontend/src/consts/api_endpoints.dart';
import '../services/auth.service.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;

  // Mutex to prevent multiple concurrent refresh calls
  Future<String?>? _refreshFuture;

  AuthInterceptor(this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthenticationService().getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final reqOptions = err.requestOptions;

    // 1. Filter: Only handle 401s that haven't been retried yet
    //    and aren't the refresh call itself.
    if (err.response?.statusCode == 401 &&
        reqOptions.extra['retried'] != true &&
        !reqOptions.path.contains(ApiEndpoints.refresh)) {
      final authService = AuthenticationService();

      // 2. CHECK: Do we even have a refresh token?
      // If not, we can't refresh, so fail immediately (propagating the 401).
      final refreshToken = await authService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return handler.next(err);
      }

      // 3. The "Lock": If no refresh is running, start one.
      _refreshFuture ??= authService
          .refresh()
          .then((session) {
            return session.accessToken;
          })
          .catchError((e) {
            // If refresh fails, we must clear the future so next time we try again.
            // Throwing here ensures the 'await' below catches it.
            throw e;
          })
          .whenComplete(() {
            // Always clear the future when done so new 401s trigger a new refresh
            _refreshFuture = null;
          });

      try {
        // 4. The "Wait": Wait for the SINGLE refresh to finish.
        final newToken = await _refreshFuture;

        // 5. The Retry: Once awake, retry with the new token.
        final retryOpts = reqOptions.copyWith(
          extra: {...reqOptions.extra, 'retried': true},
        );
        retryOpts.headers['Authorization'] = 'Bearer $newToken';

        final response = await _dio.fetch(retryOpts);
        return handler.resolve(response);
      } catch (e) {
        // If the shared refresh failed (e.g. refresh token expired),
        // everyone waiting fails gracefully with the original 401.
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
