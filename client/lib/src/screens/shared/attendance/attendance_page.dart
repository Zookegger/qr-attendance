import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_attendance_frontend/src/services/attendance.service.dart';

// Simple model to track history for the session
class AttendanceRecord {
  final String code;
  final String mode; // 'Check-In' or 'Check-Out'
  final DateTime timestamp;

  AttendanceRecord(this.code, this.mode) : timestamp = DateTime.now();
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Switched to a List to track history + mode, but we use a Set for quick duplicate checks
  final List<AttendanceRecord> _history = [];
  final Set<String> _processedCodes = {};
  final AttendanceService _attendanceService = AttendanceService();

  Future<void> _recordAttendance(String code, String mode) async {
    if (_processedCodes.contains(code)) {
      _showMessage(
        'Attendance already recorded for this code!',
        color: Colors.orange,
      );
      return;
    }

    try {
      // Check permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      final position = await Geolocator.getCurrentPosition();

      if (mode == 'Check-In') {
        await _attendanceService.checkIn(
          code: code,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else {
        await _attendanceService.checkOut(
          code: code,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      setState(() {
        _processedCodes.add(code);
        _history.insert(0, AttendanceRecord(code, mode)); // Add to top of list
      });

      _showMessage(
        '$mode successful for: $code',
        color: mode == 'Check-In' ? Colors.green : Colors.orange,
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains("No scheduled shift found for today")) {
        _showNoScheduleDialog();
      } else {
        _showMessage(msg.replaceAll("Exception: ", ""), color: Colors.red);
      }
    }
  }

  void _showNoScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("No Schedule Found"),
        content: const Text("You do not have a scheduled shift for today."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Manager'),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Check-In', icon: Icon(Icons.login)),
              Tab(text: 'Check-Out', icon: Icon(Icons.logout)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AttendanceActionTab(
              mode: 'Check-In',
              color: Colors.green,
              onRecord: (code) => _recordAttendance(code, 'Check-In'),
              history: _history,
            ),
            _AttendanceActionTab(
              mode: 'Check-Out',
              color: Colors.orange,
              onRecord: (code) => _recordAttendance(code, 'Check-Out'),
              history: _history,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceActionTab extends StatefulWidget {
  final String mode;
  final Color color;
  final Function(String) onRecord;
  final List<AttendanceRecord> history;

  const _AttendanceActionTab({
    required this.mode,
    required this.color,
    required this.onRecord,
    required this.history,
  });

  @override
  State<_AttendanceActionTab> createState() => _AttendanceActionTabState();
}

class _AttendanceActionTabState extends State<_AttendanceActionTab> {
  final TextEditingController _controller = TextEditingController();

  void _handleSubmit() {
    final code = _controller.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit code')),
      );
      return;
    }
    widget.onRecord(code);
    _controller.clear();
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerView(
          onDetected: (code) {
            widget.onRecord(code);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Section: Input
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: TextStyle(
                  fontSize: 32,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: '____',
                  hintStyle: TextStyle(color: Colors.grey.shade300),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleSubmit,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('Manual ${widget.mode}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _openScanner,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom Section: History List
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Session History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: widget.history.isEmpty
              ? const Center(
                  child: Text(
                    'No records yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  itemCount: widget.history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = widget.history[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: record.mode == 'Check-In'
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          child: Icon(
                            record.mode == 'Check-In'
                                ? Icons.login
                                : Icons.logout,
                            color: record.mode == 'Check-In'
                                ? Colors.green
                                : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          record.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '${record.mode} • ${record.timestamp.hour}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==========================================================
// SCANNER VIEW (Untouched)
// ==========================================================
class ScannerView extends StatefulWidget {
  final void Function(String code) onDetected;

  const ScannerView({super.key, required this.onDetected});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  late final MobileScannerController _controller;

  String? _lastScannedCode;
  DateTime? _lastScanTime;
  final Duration _throttleDuration = const Duration(seconds: 2);

  final ValueNotifier<String?> _lastCodeNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    _lastCodeNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showScanMessage(String message, {Color color = Colors.green}) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          backgroundColor: color,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: AiBarcodeScanner(
              controller: _controller,
              galleryButtonType: GalleryButtonType.none,
              onDetect: (BarcodeCapture capture) {
                final code = capture.barcodes.first.rawValue;
                if (code == null) return;

                final now = DateTime.now();

                if (code == _lastScannedCode &&
                    _lastScanTime != null &&
                    now.difference(_lastScanTime!) < _throttleDuration) {
                  return;
                }

                _lastScannedCode = code;
                _lastScanTime = now;
                _lastCodeNotifier.value = code;

                widget.onDetected(code);
                _showScanMessage(
                  'Attendance recorded for: $code',
                  color: Colors.green,
                );
              },
              extendBodyBehindAppBar: true,
              appBarBuilder: (context, controller) {
                return AppBar(
                  title: const Text('Attendance Scanner'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, state, child) {
                          return Icon(
                            state.torchState == TorchState.on
                                ? Icons.flash_on
                                : Icons.flash_off,
                            color: Colors.white,
                          );
                        },
                      ),
                      onPressed: () => controller.toggleTorch(),
                    ),
                    IconButton(
                      icon: ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, state, child) {
                          return Icon(
                            state.cameraDirection == CameraFacing.front
                                ? Icons.camera_front
                                : Icons.camera_rear,
                            color: Colors.white,
                          );
                        },
                      ),
                      onPressed: () => controller.switchCamera(),
                    ),
                  ],
                );
              },
            ),
          ),

          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: _lastCodeNotifier,
                  builder: (context, value, child) {
                    return Text(
                      'Last Code: ${value ?? 'N/A'}',
                      style: const TextStyle(color: Colors.white70),
                    );
                  },
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
