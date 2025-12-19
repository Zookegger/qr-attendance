import 'dart:convert';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

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
    http.Client? httpClient,
    FlutterSecureStorage? storage,
    String? baseUrl,
    DeviceInfoPlugin? deviceInfo,
  }) : _http = httpClient ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage(),
       _baseUrl = (baseUrl ?? const String.fromEnvironment('API_BASE_URL'))
           .trim(),
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  static final AuthenticationService _instance =
      AuthenticationService._internal();

  factory AuthenticationService() => _instance;

  final http.Client _http;
  final FlutterSecureStorage _storage;
  final String _baseUrl;
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
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userKey),
    ]);
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
    _ensureBaseUrl();

    final deviceUuid = await getOrCreateDeviceUuid();

    final uri = Uri.parse('$_baseUrl/auth/login');
    final res = await _http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_uuid': deviceUuid,
      }),
    );

    final body = _tryDecodeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthException(
        _extractMessage(body) ?? 'Login failed',
        res.statusCode,
      );
    }

    return _persistAndReturnSession(
      body,
      invalidMessage: 'Login succeeded but response was invalid.',
    );
  }

  Future<AuthSession> refresh() async {
    _ensureBaseUrl();

    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      throw AuthException('Missing refresh token. Please login again.');
    }

    final uri = Uri.parse('$_baseUrl/auth/refresh');
    final res = await _http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    final body = _tryDecodeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      await logout();
      throw AuthException(
        _extractMessage(body) ?? 'Token refresh failed',
        res.statusCode,
      );
    }

    return _persistAndReturnSession(
      body,
      invalidMessage: 'Refresh succeeded but response was invalid.',
    );
  }

  Future<User> me({bool attemptRefreshOn401 = true}) async {
    _ensureBaseUrl();

    Future<http.Response> doRequest(String token) {
      final uri = Uri.parse('$_baseUrl/auth/me');
      return _http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    }

    var accessToken = await getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw AuthException('Not authenticated (missing access token).');
    }

    var res = await doRequest(accessToken);
    if (res.statusCode == 401 && attemptRefreshOn401) {
      final session = await refresh();
      accessToken = session.accessToken;
      res = await doRequest(accessToken);
    }

    final body = _tryDecodeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (res.statusCode == 401) {
        await logout();
      }
      throw AuthException(
        _extractMessage(body) ?? 'Failed to fetch current user',
        res.statusCode,
      );
    }

    if (body is! Map<String, dynamic>) {
      throw AuthException('Unexpected /auth/me response format.');
    }

    final user = User.fromJson(body);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    return user;
  }

  // ---- Internals ----
  void _ensureBaseUrl() {
    if (_baseUrl.isEmpty) {
      throw AuthException(
        'API baseUrl is empty. Provide API_BASE_URL via --dart-define.',
      );
    }
  }

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

  AuthSession _persistAndReturnSession(
    Object? body, {
    required String invalidMessage,
  }) {
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
    _storage.write(key: _accessTokenKey, value: accessToken);
    _storage.write(key: _refreshTokenKey, value: refreshToken);
    _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

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
