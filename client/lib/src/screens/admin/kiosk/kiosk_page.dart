import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:qr_attendance_frontend/src/services/kiosk.service.dart';
import 'package:intl/intl.dart';
import 'package:qr_attendance_frontend/src/screens/admin/kiosk/kiosk_active_guard.dart';
import 'package:qr_attendance_frontend/src/services/auth.service.dart';
import 'package:qr_attendance_frontend/src/services/attendance.service.dart';
import 'package:qr_attendance_frontend/src/services/office_config.service.dart';

class KioskPage extends StatefulWidget {
  const KioskPage({super.key});

  @override
  State<KioskPage> createState() => _KioskPageState();
}

class _KioskPageState extends State<KioskPage> with TickerProviderStateMixin {
  final KioskService _kioskService = KioskService();

  String? _qrData;
  String? _backupCode;
  bool _isConnected = true;
  String? _lastLog;
  Timer? _logTimer;
  late AnimationController _progressController;
  bool _hostAutoCheckedIn = false;

  StreamSubscription? _qrSub;
  StreamSubscription? _logSub;
  StreamSubscription? _connSub;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _kioskService.start();

    _qrSub = _kioskService.qrStream.listen((data) {
      if (mounted) {
        setState(() {
          _backupCode = data['code'];
          _qrData = data['code'];
          final refreshAt = data['refreshAt'] ?? 30;
          _progressController.duration = Duration(seconds: refreshAt);
          _progressController.reset();
          _progressController.forward();
        });
        // Attempt auto check-in for kiosk host the first time we receive a QR
        try {
          final officeId = data['officeId'];
          if (!_hostAutoCheckedIn && officeId != null && _qrData != null) {
            _hostAutoCheckedIn = true;
            _autoCheckInHost(code: _qrData!, officeId: officeId);
          }
        } catch (e) {
          debugPrint('Auto check-in error: $e');
        }
      }
    });

    _logSub = _kioskService.logStream.listen((data) {
      if (mounted) {
        setState(() {
          _lastLog = "${data['userName']} - ${data['action']}";
        });
        _logTimer?.cancel();
        _logTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _lastLog = null);
        });
      }
    });

    _connSub = _kioskService.connectionStream.listen((connected) {
      if (mounted) setState(() => _isConnected = connected);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _kioskService.stop();
    _qrSub?.cancel();
    _logSub?.cancel();
    _connSub?.cancel();
    _logTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _handleExit() async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PasswordExitDialog(),
    );

    if (password != null && password.isNotEmpty) {
      try {
        final authService = AuthenticationService();
        final user = await authService.getCachedUser();
        if (user != null) {
          final isValid = await authService.verifyPassword(
            user.email,
            password,
          );
          if (isValid) {
            if (mounted) {
              Navigator.of(context).pop();
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid password.')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not verify user identity.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exit failed: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _autoCheckInHost({required String code, required dynamic officeId}) async {
    try {
      final authService = AuthenticationService();
      final user = await authService.getCachedUser();
      if (user == null) return;

      final officeService = OfficeConfigService();
      final offices = await officeService.getOfficeConfigs();
      final matches = offices.where((o) => o.id == officeId).toList();
      if (matches.isEmpty) return;
      final office = matches.first;

      final lat = office.latitude;
      final lon = office.longitude;

      await AttendanceService().checkIn(code: code, latitude: lat, longitude: lon);

      if (mounted) {
        setState(() {
          _lastLog = '${user.name} - Auto Check In';
        });
      }
    } catch (e) {
      debugPrint('Auto check-in failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return KioskActiveGuard(
      startHour: 6,
      endHour: 22,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Stack(
          children: [
            AbsorbPointer(
              absorbing: true,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OrientationBuilder(
                    builder: (context, orientation) {
                      return orientation == Orientation.portrait
                          ? _buildPortraitLayout()
                          : _buildLandscapeLayout();
                    },
                  ),
                ),
              ),
            ),

            // Progress Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: AbsorbPointer(
                  absorbing: true,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: 1.0 - _progressController.value,
                        backgroundColor: Colors.transparent,
                        color: Colors.greenAccent,
                        minHeight: 4,
                      );
                    },
                  ),
                ),
              ),
            ),

            // Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white70,
                ),
                onPressed: _handleExit,
              ),
            ),

            // Offline Overlay
            if (!_isConnected)
              Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.redAccent,
                        size: 60,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No Connection",
                        style: TextStyle(
                          color: Colors.redAccent.shade100,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Layouts ---

  Widget _buildPortraitLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(flex: 2, child: Center(child: _buildClock(fontSize: 64))),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: _buildQrCard()),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusPill(),
              const SizedBox(height: 16),
              _buildCodeDisplay(fontSize: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left: Big QR Code
        Expanded(
          flex: 3,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildQrCard(),
            ),
          ),
        ),

        // Right: Info Column
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildClock(fontSize: 50),
              const Spacer(),
              _buildStatusPill(),
              const SizedBox(height: 20),
              _buildCodeDisplay(fontSize: 60),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  // --- Components ---

  Widget _buildQrCard() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),

        padding: const EdgeInsets.all(6),
        child: _qrData != null
            ? QrImageView(
                data: _qrData!,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
      ),
    );
  }

  Widget _buildClock({required double fontSize}) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('HH:mm').format(now),
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, d MMMM').format(now).toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: fontSize * 0.25, // Scale date relative to time
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusPill() {
    if (_lastLog == null) return const SizedBox(height: 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
      ),
      child: Text(
        _lastLog!,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCodeDisplay({required double fontSize}) {
    return Text(
      _backupCode ?? "----",
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 8,
        color: Colors.white,
      ),
    );
  }
}

class PasswordExitDialog extends StatefulWidget {
  const PasswordExitDialog({super.key});

  @override
  State<PasswordExitDialog> createState() => _PasswordExitDialogState();
}

class _PasswordExitDialogState extends State<PasswordExitDialog> {
  // Controller is now owned by this widget, preventing external dispose errors
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exit Kiosk Mode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your password to exit.'),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true, // Quality of life improvement
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _passwordController.text),
          child: const Text('Exit'),
        ),
      ],
    );
  }
}
