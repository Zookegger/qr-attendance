import 'dart:async';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:qr_attendance_frontend/src/consts/api_endpoints.dart';
import 'package:qr_attendance_frontend/src/services/config.service.dart';

enum HealthStatus { unknown, healthy, unhealthy }

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final StreamController<HealthStatus> _controller =
      StreamController<HealthStatus>.broadcast();
  Stream<HealthStatus> get streamStatus => _controller.stream;

  IO.Socket? _socket;
  Timer? _pollTimer;
  HealthStatus _last = HealthStatus.unknown;

  void start({
    bool enableSocket = true,
    Duration pollInterval = const Duration(seconds: 10),
  }) {
    if (_pollTimer != null || (_socket != null && _socket!.connected)) return;
    // start periodic polling
    _pollTimer = Timer.periodic(pollInterval, (_) => checkOnce());

    if (enableSocket) _startSocket();
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _stopSocket();
    _emit(HealthStatus.unknown);
  }

  void _emit(HealthStatus status) {
    if (_last == status) return;
    _last = status;
    if (!_controller.isClosed) _controller.add(status);
  }

  void _startSocket() {
    final base = ConfigService().baseUrl;
    if (base.isEmpty) return;

    final socketUrl = base.replaceAll(RegExp(r'\/api\/?$'), '');

    try {
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.on('connect', (_) => _emit(HealthStatus.healthy));
      _socket?.on('disconnect', (_) => _emit(HealthStatus.unhealthy));
      _socket?.on('connect_error', (_) => _emit(HealthStatus.unhealthy));

      // optionally listen to a custom server health event if you emit one
      _socket?.on('health:update', (data) {
        // server can emit payload like { healthy: true }
        if (data is Map && data.containsKey('healthy')) {
          _emit(
            data['healthy'] == true
                ? HealthStatus.healthy
                : HealthStatus.unhealthy,
          );
        }
      });
    } catch (_) {}
  }

  void _stopSocket() {
    try {
      _socket?.disconnect();
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
  }

  Future<bool> checkOnce({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final base = ConfigService().baseUrl;
    if (base.isEmpty) return false;
    final dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: timeout,
        receiveTimeout: timeout,
      ),
    );
    try {
      final res = await dio.get(ApiEndpoints.health);
      final ok = res.statusCode == 200;
      _emit(ok ? HealthStatus.healthy : HealthStatus.unhealthy);
      return ok;
    } catch (_) {
      _emit(HealthStatus.unhealthy);
      return false;
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
