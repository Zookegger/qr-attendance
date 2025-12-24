import 'dart:convert';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_attendance_frontend/src/consts/api_endpoints.dart';
import '../models/user.dart';
import 'api/api_client.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, [this.statusCode]);

  @override
  String toString() => '[AuthException | $statusCode]: $message';
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final User user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

// Matches server contract:
// - POST /auth/login   -> { accessToken, refreshToken, user }
// - POST /auth/refresh -> { accessToken, refreshToken, user }
// - GET  /auth/me (Bearer accessToken) -> user
// - POST /auth/logout  -> {  }
// NOTE: Server requires `device_uuid` on login for non-admin users.
class AuthenticationService {
  AuthenticationService._internal({
    FlutterSecureStorage? storage,
    DeviceInfoPlugin? deviceInfo,
    Dio? dio,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _dio = dio ?? ApiClient().client;

  static final AuthenticationService _instance =
      AuthenticationService._internal();

  factory AuthenticationService() => _instance;

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfo;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user_json';
  static const _deviceUuidKey = 'device_uuid';

  // ---- Public API ----

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<User?> getCachedUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = _tryDecodeJson(raw);
    if (decoded is Map<String, dynamic>) return User.fromJson(decoded);
    return null;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        await _dio.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (e) {
      debugPrint('Logout request failed: $e');
    } finally {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userKey),
      ]);
    }
  }

  Future<String> getOrCreateDeviceUuid() async {
    final existing = await _storage.read(key: _deviceUuidKey);
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final created = _generateDeviceUuid();
    await _storage.write(key: _deviceUuidKey, value: created);
    return created;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final deviceUuid = await getOrCreateDeviceUuid();

    try {
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password, 'device_uuid': deviceUuid},
      );

      debugPrint(res.toString());

      return _persistAndReturnSession(
        res.data,
        invalidMessage: 'Login succeeded but response was invalid.',
      );
    } on DioException catch (e) {
      throw AuthException(
        _extractMessage(e.response?.data) ?? 'Login failed',
        e.response?.statusCode,
      );
    }
  }

  Future<AuthSession> refresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      throw AuthException('Missing refresh token. Please login again.');
    }

    try {
      final res = await _dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      return _persistAndReturnSession(
        res.data,
        invalidMessage: 'Refresh succeeded but response was invalid.',
      );
    } on DioException catch (e) {
      await logout();
      throw AuthException(
        _extractMessage(e.response?.data) ?? 'Token refresh failed',
        e.response?.statusCode,
      );
    }
  }

  Future<User> me({bool attemptRefreshOn401 = true}) async {
    Future<Response> doRequest(String token) {
      return _dio.get(
        ApiEndpoints.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    }

    var accessToken = await getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw AuthException('Not authenticated (missing access token).');
    }

    try {
      var res = await doRequest(accessToken);
      final body = res.data;

      if (body is! Map<String, dynamic>) {
        throw AuthException('Unexpected /auth/me response format.');
      }

      final user = User.fromJson(body);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && attemptRefreshOn401) {
        try {
          final session = await refresh();
          final res = await doRequest(session.accessToken);
          final body = res.data;
          if (body is! Map<String, dynamic>) {
            throw AuthException('Unexpected /auth/me response format.');
          }
          final user = User.fromJson(body);
          await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
          return user;
        } on AuthException {
          rethrow;
        } catch (_) {
          await logout();
          throw AuthException(
            'Failed to fetch current user after refresh',
            401,
          );
        }
      }

      if (e.response?.statusCode == 401) {
        await logout();
      }
      throw AuthException(
        _extractMessage(e.response?.data) ?? 'Failed to fetch current user',
        e.response?.statusCode,
      );
    }
  }

  // ---- Internals ----
  Object? _tryDecodeJson(String s) {
    try {
      if (s.trim().isEmpty) return null;
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  String? _extractMessage(Object? body) {
    if (body is Map<String, dynamic>) {
      final msg = body['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
      final err = body['error'];
      if (err is String && err.trim().isNotEmpty) return err;
    }
    return null;
  }

  Future<AuthSession> _persistAndReturnSession(
    Object? body, {
    required String invalidMessage,
  }) async {
    if (body is! Map<String, dynamic>) {
      throw AuthException(invalidMessage);
    }

    final accessToken = body['accessToken'];
    final refreshToken = body['refreshToken'];
    final userJson = body['user'];

    if (accessToken is! String || accessToken.trim().isEmpty) {
      throw AuthException(invalidMessage);
    }
    if (refreshToken is! String || refreshToken.trim().isEmpty) {
      throw AuthException(invalidMessage);
    }
    if (userJson is! Map<String, dynamic>) {
      throw AuthException(invalidMessage);
    }

    final user = User.fromJson(userJson);

    // Persist tokens and user
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);

    // Best-effort device info fetch (ensures plugin is initialized/used)
    // ignore: discarded_futures
    _bestEffortLogDeviceInfo();

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
  }

  String _generateDeviceUuid() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _bestEffortLogDeviceInfo() async {
    try {
      await _deviceInfo.deviceInfo;
    } catch (_) {
      // ignore errors
    }
  }
}
