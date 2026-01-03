import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:qr_attendance_frontend/src/services/kiosk.service.dart';
import 'package:intl/intl.dart';
import 'package:qr_attendance_frontend/src/screens/admin/kiosk/kiosk_active_guard.dart';

class KioskPage extends StatefulWidget {
  const KioskPage({super.key});

  @override
  State<KioskPage> createState() => _KioskPageState();
}

class _KioskPageState extends State<KioskPage> {
  final KioskService _kioskService = KioskService();
  
  String? _qrData;
  String? _backupCode;
  bool _isConnected = true;
  String? _lastLog;
  Timer? _logTimer;

  StreamSubscription? _qrSub;
  StreamSubscription? _logSub;
  StreamSubscription? _connSub;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _kioskService.start();
    
    _qrSub = _kioskService.qrStream.listen((data) {
      if (mounted) {
        setState(() {
          _backupCode = data['code'];
          _qrData = data['code']; 
        });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KioskActiveGuard(
      startHour: 6,
      endHour: 22,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Row(
              children: [
                // Left Side: Clock & Status
                Expanded(
                  flex: 4,
                  child: Container(
                    color: const Color(0xFF1E1E1E),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildClock(),
                        const SizedBox(height: 40),
                        if (_lastLog != null)
                          Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Text(
                              _lastLog!,
                              style: const TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          const Text(
                            "Ready to Scan",
                            style: TextStyle(color: Colors.grey, fontSize: 24),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Right Side: QR Code
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_qrData != null)
                          QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 400.0,
                          )
                        else
                          const CircularProgressIndicator(),
                        
                        const SizedBox(height: 40),
                        const Text(
                          "Backup Code",
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        Text(
                          _backupCode ?? "----",
                          style: const TextStyle(
                            fontSize: 60, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 10,
                            color: Colors.black
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            if (!_isConnected)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.red),
                      SizedBox(height: 20),
                      Text(
                        "Reconnecting...",
                        style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),

            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClock() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        return Column(
          children: [
            Text(
              DateFormat('HH:mm').format(DateTime.now()),
              style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: const TextStyle(color: Colors.grey, fontSize: 24),
            ),
          ],
        );
      },
    );
  }
}
