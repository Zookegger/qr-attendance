import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../services/health.service.dart';

class ConnectionStatusOverlay extends StatefulWidget {
  final Widget child;
  const ConnectionStatusOverlay({super.key, required this.child});

  @override
  State<ConnectionStatusOverlay> createState() =>
      _ConnectionStatusOverlayState();
}

class _ConnectionStatusOverlayState extends State<ConnectionStatusOverlay> {
  late StreamSubscription<List<ConnectivityResult>> _netSub;
  late StreamSubscription<HealthStatus> _healthSub;

  bool _hasLocalNet = true;
  HealthStatus _serverHealth = HealthStatus.unknown;

  // Display State
  bool _isVisible = false;
  String _message = "";
  Color _color = Colors.green;
  IconData _icon = Icons.check;
  Timer? _dismissTimer;

  // To track logic changes
  String? _currentErrorType;

  @override
  void initState() {
    super.initState();
    HealthService().start();

    _netSub = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      _updateState(newNet: !isOffline);
    });

    _healthSub = HealthService().streamStatus.listen((status) {
      _updateState(newHealth: status);
    });
  }

  void _updateState({bool? newNet, HealthStatus? newHealth}) {
    if (newNet != null) _hasLocalNet = newNet;
    if (newHealth != null) _serverHealth = newHealth;

    String? newErrorType;
    String message = "";
    Color color = Colors.green;
    IconData icon = Icons.check;

    // --- Priority Logic ---
    if (!_hasLocalNet) {
      newErrorType = 'net';
      message = "No Internet Connection";
      color = Colors.red;
      icon = Icons.wifi_off;
    } else if (_serverHealth == HealthStatus.unhealthy) {
      newErrorType = 'server';
      message = "Server Unreachable";
      color = Colors.orange.shade800;
      icon = Icons.cloud_off;
    } else {
      newErrorType = null; // Online
    }

    if (newErrorType != _currentErrorType) {
      if (newErrorType != null) {
        // CASE: Error Occurred (Show Persistent)
        _showBanner(message, color, icon, persistent: true);
      } else {
        // CASE: Back Online (Show Brief Success)
        if (_currentErrorType != null) {
          _showBanner(
            "Back Online",
            Colors.green,
            Icons.wifi,
            persistent: false,
          );
        } else {
          _hideBanner();
        }
      }
      _currentErrorType = newErrorType;
    }
  }

  void _showBanner(
    String msg,
    Color color,
    IconData icon, {
    required bool persistent,
  }) {
    _dismissTimer?.cancel();

    setState(() {
      _message = msg;
      _color = color;
      _icon = icon;
      _isVisible = true;
    });

    if (!persistent) {
      _dismissTimer = Timer(const Duration(seconds: 3), _hideBanner);
    }
  }

  void _hideBanner() {
    if (mounted) {
      setState(() => _isVisible = false);
    }
  }

  @override
  void dispose() {
    _netSub.cancel();
    _healthSub.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the top position:
    // If visible: SafeArea top + padding
    // If hidden: completely off-screen (-100)
    final topPadding = MediaQuery.of(context).padding.top;
    final topPosition = _isVisible ? topPadding + 16 : -100.0;

    return Stack(
      children: [
        // 1. The App Screen
        widget.child,

        // 2. The Floating Banner
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutBack, // Adds a nice bounce effect
          top: topPosition,
          left: 0,
          right: 0,
          child: Center(
            // Center constraint forces the child to wrap its content
            child: Material(
              color: _color,
              elevation: 6,
              borderRadius: BorderRadius.circular(30), // Pill shape
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Shrink width to fit content
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_icon, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
