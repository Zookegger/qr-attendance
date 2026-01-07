import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:qr_attendance_frontend/src/services/config.service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  IO.Socket? _socket;

  final StreamController<Map<String, dynamic>> _statsUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statsUpdateStream =>
      _statsUpdateController.stream;

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null && _socket!.connected) {
      debugPrint("Dashboard Socket already connected");
      return;
    }

    final base = ConfigService().baseUrl;
    if (base.isEmpty) {
      debugPrint("Cannot connect: baseUrl is empty");
      return;
    }

    final socketUrl = base.replaceAll(RegExp(r'\/api\/?$'), '');

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket?.on('connect', (_) {
      debugPrint("Dashboard Socket Connected");
      _connectionController.add(true);
    });

    _socket?.on('disconnect', (_) {
      debugPrint("Dashboard Socket Disconnected");
      _connectionController.add(false);
    });

    _socket?.on('stats:update', (data) {
      if (data != null) {
        debugPrint("Stats update received: $data");
        _statsUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('connect_error', (error) {
      debugPrint("Dashboard Socket connection error: $error");
    });
  }

  void disconnect() {
    if (_socket != null) {
      debugPrint("Disconnecting Dashboard Socket");
      _socket?.disconnect();
      _socket = null;
    }
  }

  void dispose() {
    disconnect();
    _statsUpdateController.close();
    _connectionController.close();
  }
}
