import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // Shared attendance log for the session
  final Set<String> _attendanceLog = {};

  // Scanner controller will be created when ScannerView is pushed to avoid
  // holding camera resources while on the code input screen.

  void _recordAttendance(String code, String mode) {
    if (_attendanceLog.contains(code)) {
      _showMessage(
        'Attendance already recorded for this code!',
        color: Colors.orange,
      );
      return;
    }

    setState(() => _attendanceLog.add(code));
    _showMessage('$mode successful for: $code', color: Colors.green);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Total Attendance: ${_attendanceLog.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),

            // Buttons: Check-In / Check-Out
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CodeEntryPage(
                    mode: 'Check-In',
                    onSubmit: (code) => _recordAttendance(code, 'Check-In'),
                    openScanner: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScannerView(
                          onDetected: (code) =>
                              _recordAttendance(code, 'Check-In'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Check-In', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CodeEntryPage(
                    mode: 'Check-Out',
                    onSubmit: (code) => _recordAttendance(code, 'Check-Out'),
                    openScanner: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScannerView(
                          onDetected: (code) =>
                              _recordAttendance(code, 'Check-Out'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Check-Out', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Recent codes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: _attendanceLog.isEmpty
                    ? [const Text('No attendance logged yet.')]
                    : _attendanceLog
                          .map((c) => ListTile(title: Text(c)))
                          .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CodeEntryPage extends StatefulWidget {
  final String mode; // 'Check-In' or 'Check-Out'
  final void Function(String code) onSubmit;
  final VoidCallback openScanner;

  const CodeEntryPage({
    super.key,
    required this.mode,
    required this.onSubmit,
    required this.openScanner,
  });

  @override
  State<CodeEntryPage> createState() => _CodeEntryPageState();
}

class _CodeEntryPageState extends State<CodeEntryPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit code')),
      );
      return;
    }
    widget.onSubmit(code);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: widget.openScanner,
            tooltip: 'Open QR scanner',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Enter 4-digit code to ${widget.mode.toLowerCase()}:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. 1234',
                counterText: '',
              ),
              style: const TextStyle(letterSpacing: 8, fontSize: 20),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _submit, child: Text(widget.mode)),
          ],
        ),
      ),
    );
  }
}

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
