import 'dart:convert';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../../services/config.service.dart';

class ServerSetupPage extends StatefulWidget {
  const ServerSetupPage({super.key});

  @override
  State<ServerSetupPage> createState() => _ServerSetupPageState();
}

class _ServerSetupPageState extends State<ServerSetupPage> {
  // Default to Manual Input
  bool _isScanMode = false;

  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    facing: CameraFacing.back,
    autoZoom: true,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final TextEditingController _urlController = TextEditingController();
  bool _isConnecting = false;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() => _cameraGranted = status.isGranted);

      if (_cameraGranted) {
        _scannerController.start();
      } else if (status.isPermanentlyDenied) {
        _showSettingDialog();
      }
    }
  }

  void _toggleMode() {
    if (_isScanMode) {
      _scannerController.stop();
    }

    setState(() {
      _isScanMode = !_isScanMode;
    });

    if (_isScanMode) {
      _requestPermissions();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(code);
      if (data.containsKey('host')) {
        _connectToServer(data['host']);
      }
    } catch (_) {}
  }

  void _onManualSubmit() {
    final input = _urlController.text.trim();
    if (input.isEmpty) return;
    String url = input;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    _connectToServer(url);
  }

  void _showSettingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Camera Permission"),
        content: const Text(
          "Camera access is permanently denied. Please enable it in your system settings to use the scanner.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToServer(String host) async {
    if (_isConnecting) return;

    final normalizedHost =
        '${host.endsWith('/') ? host.substring(0, host.length - 1) : host}/api';

    try {
      setState(() => _isConnecting = true);
      final dio = Dio(
        BaseOptions(
          baseUrl: normalizedHost,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await dio.get('/health');

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code ${response.statusCode}',
        );
      }

      await ConfigService().setBaseUrl(normalizedHost);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connected to $normalizedHost"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacementNamed('/login');
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to connect. Please check the address and try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connect to Server")),
      body: _isScanMode ? _buildScannerView() : _buildManualView(),
    );
  }

  // --- Mode 1: Full Screen Scanner ---
  Widget _buildScannerView() {
    if (!_cameraGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Camera permission is required."),
            const SizedBox(height: 16),
            TextButton(onPressed: _toggleMode, child: const Text("Go Back")),
          ],
        ),
      );
    }
    return Stack(
      children: [
        AiBarcodeScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          galleryButtonType: GalleryButtonType.none,
          // Note: errorBuilder signature depends on package version,
          // usually it is (context, error)
          errorBuilder: (context, error) =>
              const Center(child: Text("Camera Error")),
        ),

        // Overlay: Instructions
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "Scan the Admin QR Code",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),

        // Overlay: Switch Button
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _toggleMode,
              icon: const Icon(Icons.keyboard),
              label: const Text("Enter Address Manually"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Mode 2: Clean Manual Input Form ---
  Widget _buildManualView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.dns_outlined, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text(
              "Enter Server Address",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Enter the IP address provided by your admin.",
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _onManualSubmit(),
              decoration: InputDecoration(
                labelText: "Server URL",
                hintText: "e.g. http://192.168.1.10:3000",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.link),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _onManualSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Connect",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            TextButton.icon(
              onPressed: _toggleMode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Scan QR Code instead"),
              style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }
}
