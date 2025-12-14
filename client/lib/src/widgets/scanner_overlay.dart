import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  final Rect scanWindow;
  final Color overlayColor;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;

  const ScannerOverlay({
    super.key,
    required this.scanWindow,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.borderRadius = 12.0,
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerOverlayPainter(
        scanWindow: scanWindow,
        overlayColor: overlayColor,
        borderRadius: borderRadius,
        borderColor: borderColor,
        borderWidth: borderWidth,
      ),
      child: Container(),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color overlayColor;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;

  _ScannerOverlayPainter({
    required this.scanWindow,
    required this.overlayColor,
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Create the background path (full screen)
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 2. Create the cutout path (scan window)
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanWindow,
          Radius.circular(borderRadius),
        ),
      );

    // 3. Combine them using difference to create the hole
    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // 4. Draw the darkened background
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(backgroundWithCutout, backgroundPaint);

    // 5. Draw the border around the cutout
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        scanWindow,
        Radius.circular(borderRadius),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
