import 'dart:async';
import 'package:dio/dio.dart';
import '../services/auth.service.dart';

class AuthInterceptor extends Interceptor {
  final AuthenticationService _auth = AuthenticationService();
  final Dio _dio;
  bool _isRefreshing = false;
  final List<Completer<Response>> _queue = [];

  AuthInterceptor(this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _auth.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Au thorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final reqOptions = err.requestOptions;

    if (status == 401 &&
        reqOptions.extra['retried'] != true &&
        reqOptions.path != '/auth/refresh') {
      final completer = Completer<Response>();
      _queue.add(completer);

      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final session = await _auth.refresh();
          final newAccess = session.accessToken;

          for (final q in _queue) {
            final opts = reqOptions.copyWith();
            opts.headers['Authorization'] = 'Bearer $newAccess';
            opts.extra['retried'] = true;
            _dio
                .fetch(opts)
                .then((r) => q.complete(r))
                .catchError((e) => q.completeError(e));
          }
        } catch (e) {
          await _auth.logout();
          for (final q in _queue) {
            q.completeError(
              DioException(
                requestOptions: reqOptions,
                error: 'Auth refresh failed',
              ),
            );
          }
        } finally {
          _queue.clear();
          _isRefreshing = false;
        }
      }

      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
