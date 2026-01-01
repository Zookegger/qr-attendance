import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_attendance_frontend/src/consts/api_endpoints.dart';
import '../models/user.dart';
import '../utils/api_client.dart';

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

  // Key names in secure storage
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user_json';
  static const _deviceUuidKey = 'device_binding_uuid';

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

  Future<bool> logout() async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null || refreshToken.trim().isEmpty) {
        return false;
      }

      final response = await _dio.post(
        ApiEndpoints.logout,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      final bool success =
          data is Map<String, dynamic> && data['success'] == true;

      if (response.statusCode != 200 && !success) {
        return false;
      }

      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userKey),
      ]);

      return true;
    } catch (e) {
      debugPrint('Logout request failed: $e');
      return false;
    }
  }

  Future<String> getOrCreateDeviceUuid(BuildContext context) async {
    // 1. Fast Path: Check Storage
    final existing = await _storage.read(key: _deviceUuidKey);
    if (existing != null && existing.trim().isNotEmpty) return existing;

    // Guard: Context safety
    if (!context.mounted) throw AuthException("Login interrupted.");

    // 2. Show "Data Policy" Dialog (Static Content)
    final bool? userAgreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Device Binding Policy",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Divider(),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "1. SECURITY REQUIREMENT",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "To ensure attendance integrity and prevent unauthorized proxy logins, this application utilizes strict device binding.",
                style: TextStyle(fontSize: 16, height: 1.4),
                textAlign: TextAlign.left,
              ),

              const SizedBox(height: 20),

              const Text(
                "2. DATA COLLECTION",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "By proceeding, you authorize the system to capture and permanently link the following hardware identifiers to your employee profile:",
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 10),

              // --- STATIC DATA LIST ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "• Unique Device Identifier (UUID)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "• Device Model Name",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "• Operating System Version",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // -----------------------
              const SizedBox(height: 20),

              const Text(
                "3. BINDING AGREEMENT",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "This action is irreversible by the user. Unbinding a device (e.g., lost phone, new phone) requires a formal request to the System Administrator.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[700]),
            child: const Text("Decline"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            child: const Text("Agree"),
          ),
        ],
      ),
    );

    if (userAgreed != true) {
      throw AuthException("You must accept the Device Policy to continue.");
    }

    // 3. Request Permissions (Android)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Permission.phone.request();
    }

    // 4. Execution
    final created = await _generateDeviceUuid();
    await _storage.write(key: _deviceUuidKey, value: created);

    return created;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    final deviceUuid = await getOrCreateDeviceUuid(context);

    final deviceDetails = await _getDeviceDetails();

    try {
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          'device_uuid': deviceUuid,
          ...deviceDetails,
        },
      );

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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      // Assuming 404 means user not found, which we might want to hide for security,
      // but for internal apps, showing the error is fine.
      final msg = _extractMessage(e.response?.data) ?? 'Request failed';
      throw AuthException(msg, e.response?.statusCode);
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

  // Returns true when running in a development context. This allows tests
  // and local development to bypass strict physical-device checks.
  bool get _isDevelopment {
    const env = String.fromEnvironment('ENV', defaultValue: '');
    return kDebugMode || env == 'development';
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

  Future<String> _generateDeviceUuid() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? _generateRandomUuid();
      }
    } catch (e) {
      debugPrint('Failed to get hardware ID: $e');
    }
    return _generateRandomUuid();
  }

  Future<Map<String, String>> _getDeviceDetails() async {
    String deviceName = 'Unknown Device';
    String deviceModel = 'Unknown Model';
    String osVersion = 'Unknown OS';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        if (!androidInfo.isPhysicalDevice && !_isDevelopment) {
          throw AuthException("Emulators are strictly prohibited.");
        }

        // Example: "Galaxy S23"
        final productName = androidInfo.name;
        // Example: "SM-G991B"
        final model = androidInfo.model;

        deviceName = '$productName $model';
        deviceModel = model;
        osVersion =
            'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;

        if (!iosInfo.isPhysicalDevice && !_isDevelopment) {
          throw AuthException("Simulators are strictly prohibited.");
        }

        // Example: "John's iPhone"
        deviceName = iosInfo.name;
        // Example: "iPhone15,3" (Machine ID is more specific than 'model')
        deviceModel = iosInfo.utsname.machine;
        osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }
    } on AuthException {
      // CRITICAL: If we caught an emulator error, RETHROW it.
      // Do not let the function return "Unknown" and allow login.
      rethrow;
    } catch (e) {
      debugPrint('Error reading device details: $e');
    }

    return {
      'device_name': deviceName,
      'device_model': deviceModel,
      'os_version': osVersion,
    };
  }

  String _generateRandomUuid() {
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

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.resetPassword,
        data: {'email': email, 'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      final msg =
          _extractMessage(e.response?.data) ?? 'Failed to reset password';
      throw AuthException(msg, e.response?.statusCode);
    } catch (e) {
      throw AuthException('An unexpected error occurred: $e');
    }
  }
}
