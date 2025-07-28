import 'package:flutter/material.dart';

class OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ovalWidth = size.width * 0.75;
    final ovalHeight = size.height * 0.50;
    final rect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Draw overlay everywhere except the oval
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final overlayPath = Path()..addRect(Offset.zero & size);
    final ovalPath = Path()..addOval(rect);
    final maskPath =
        Path.combine(PathOperation.difference, overlayPath, ovalPath);
    canvas.drawPath(maskPath, overlayPaint);

    // Draw dashed oval border
    final dashPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const dashLength = 12.0;
    const gapLength = 8.0;
    final perimeter = 2 * 3.141592653589793 * ((ovalWidth + ovalHeight) / 4);
    final dashCount = (perimeter / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle =
          (i * (dashLength + gapLength)) / ((ovalWidth + ovalHeight) / 4);
      final endAngle = startAngle + dashLength / ((ovalWidth + ovalHeight) / 4);
      final path = Path();
      path.addArc(rect, startAngle, endAngle - startAngle);
      canvas.drawPath(path, dashPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
