import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:qr_attendance_frontend/src/consts/api_endpoints.dart';
import 'package:qr_attendance_frontend/src/services/config.service.dart';
import 'package:qr_attendance_frontend/src/utils/api_client.dart';

class KioskService {
  static final KioskService _instance = KioskService._internal();
  factory KioskService() => _instance;
  KioskService._internal();

  int? _officeId;
  final Dio _dio = ApiClient().client;
  IO.Socket? _socket;

  final StreamController<Map<String, dynamic>> _qrController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get qrStream => _qrController.stream;

  final StreamController<Map<String, dynamic>> _logController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get logStream => _logController.stream;

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> start() async {
    await _fetchInitialQr();
    _connectSocket();
  }

  void stop() {
    _socket?.disconnect();
    _socket = null;
  }

  Future<void> _fetchInitialQr() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminQr);
      if (response.statusCode == 200 && response.data != null) {
        _qrController.add(Map<String, dynamic>.from(response.data));
        if (response.data['officeId'] != null) {
          _officeId = response.data['officeId'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching initial QR: $e");
    }
  }

  void _connectSocket() {
    final base = ConfigService().baseUrl;
    if (base.isEmpty) return;

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
      debugPrint("Kiosk Socket Connected");
      _connectionController.add(true);
      if (_officeId != null) {
        _socket?.emit('join:office', _officeId);
      }
    });

    _socket?.on('disconnect', (_) {
      debugPrint("Kiosk Socket Disconnected");
      _connectionController.add(false);
    });

    _socket?.on('qr:update', (data) {
      if (data != null) {
        _qrController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('attendance:log', (data) {
      if (data != null) {
        _logController.add(Map<String, dynamic>.from(data));
      }
    });
  }
}
