import 'dart:async';
import 'package:dio/dio.dart';
import '../services/auth.service.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;

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
    // and aren't the refresh call itself.
    if (err.response?.statusCode == 401 &&
        reqOptions.extra['retried'] != true &&
        !reqOptions.path.contains('/auth/refresh')) {
      // 2. The "Lock": If no refresh is running, start one.
      // If one IS running, this will be skipped and we'll just join the existing future.
      _refreshFuture ??= AuthenticationService()
          .refresh()
          .then((session) {
            return session.accessToken;
          })
          .catchError((e) {
            // If refresh fails, we must clear the future so next time we try again
            // throwing here ensures the 'await' below catches it.
            throw e;
          })
          .whenComplete(() {
            // Always clear the future when done so new 401s trigger a new refresh
            _refreshFuture = null;
          });

      try {
        // 3. The "Wait": Everyone waits here for the SINGLE refresh to finish.
        final newToken = await _refreshFuture;

        // 4. The Retry: Once awake, every request retries ITSELF.
        // We don't need a queue because 'reqOptions' here is still
        // bound to the specific error instance of this scope.
        final retryOpts = reqOptions.copyWith();
        retryOpts.headers['Authorization'] = 'Bearer $newToken';
        retryOpts.extra['retried'] = true;

        final response = await _dio.fetch(retryOpts);
        return handler.resolve(response);
      } catch (e) {
        // If the shared refresh failed, everyone fails gracefully.
        // Optional: Logout only once here if needed, or let AuthService handle it.
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
