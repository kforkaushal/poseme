import 'package:flutter/material.dart';

/// Draws a subtle '+' crosshair mark at the exact center of the viewfinder
/// to aid composition and leveling.
class CameraCrosshair extends StatelessWidget {
  const CameraCrosshair({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CustomPaint(
            painter: _CrosshairPainter(),
          ),
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const armLength = 10.0;
    const gap = 3.0;

    // Horizontal left & right arms
    canvas.drawLine(Offset(cx - gap - armLength, cy), Offset(cx - gap, cy), paint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + gap + armLength, cy), paint);

    // Vertical top & bottom arms
    canvas.drawLine(Offset(cx, cy - gap - armLength), Offset(cx, cy - gap), paint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + gap + armLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
