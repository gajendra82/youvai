import 'package:flutter/material.dart';
import '../models/skin_analysis_model.dart';

class PatchPainter extends CustomPainter {
  final List<SkinPatch> patches;
  final Size imageSize;
  final Size displaySize;
  final SkinIssueType? selectedType;

  PatchPainter({
    required this.patches,
    required this.imageSize,
    required this.displaySize,
    this.selectedType,
  });

  final Paint linePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;

  final TextStyle labelStyle = const TextStyle(
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  final List<Rect> usedLabelRects = [];

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = displaySize.width / imageSize.width;
    final double scaleY = displaySize.height / imageSize.height;

    final Map<SkinIssueType, List<Offset>> conditionPoints = {};

    for (var patch in patches) {
      if (selectedType != null && patch.issueType != selectedType) continue;

      final Offset offset;
      if (patch.rect != null) {
        offset = Offset(
          (patch.rect!.left + patch.rect!.right) / 2 * scaleX,
          (patch.rect!.top + patch.rect!.bottom) / 2 * scaleY,
        );
      } else if (patch.polygon != null && patch.polygon!.isNotEmpty) {
        final poly = patch.polygon!;
        final center = poly.reduce((a, b) => a + b) / poly.length.toDouble();
        offset = Offset(center.dx * scaleX, center.dy * scaleY);
      } else {
        continue;
      }

      conditionPoints.putIfAbsent(patch.issueType, () => []).add(offset);
    }

    for (var entry in conditionPoints.entries) {
      final condition = entry.key;
      final points = entry.value;

      if (points.isEmpty) continue;

      final Offset basePoint = points.length > 6
          ? points.reduce((a, b) => a + b) / points.length.toDouble()
          : points[0];

      final Offset labelOffset = _calculateLabelOffset(basePoint, size);

      // Line direction vector (normalized)
      Offset dir = labelOffset - basePoint;
      double length = dir.distance;
      if (length == 0) continue; // Prevent divide by zero
      dir = Offset(dir.dx / length, dir.dy / length);

      // Draw line touching circle edge, not going inside
      const double radius = 3;
      final Offset lineStart = basePoint + dir * radius;
      canvas.drawLine(lineStart, labelOffset, linePaint);

      // Hollow circle
      canvas.drawCircle(basePoint, radius, linePaint);

      // Draw label text
      final textSpan = TextSpan(
        text: condition.name.toUpperCase(),
        style: labelStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final adjustedLabel = _adjustForOverlap(
          labelOffset + const Offset(4, -4), textPainter.size);
      textPainter.paint(canvas, adjustedLabel);

      usedLabelRects.add(Rect.fromLTWH(
        adjustedLabel.dx,
        adjustedLabel.dy,
        textPainter.width,
        textPainter.height,
      ));
    }
  }

  Offset _calculateLabelOffset(Offset base, Size canvasSize) {
    const double offsetDistance = 50;
    bool isLeft = base.dx < canvasSize.width / 2;
    bool isTop = base.dy < canvasSize.height / 2;

    double dx = base.dx + (isLeft ? -offsetDistance : offsetDistance);
    double dy = base.dy + (isTop ? -offsetDistance / 2 : offsetDistance / 2);

    dx = dx.clamp(0.0, canvasSize.width - 40);
    dy = dy.clamp(0.0, canvasSize.height - 12);

    return Offset(dx, dy);
  }

  Offset _adjustForOverlap(Offset proposed, Size size) {
    const double spacing = 4;
    Offset adjusted = proposed;
    bool hasOverlap;

    do {
      hasOverlap = false;
      for (final rect in usedLabelRects) {
        final newRect =
            Rect.fromLTWH(adjusted.dx, adjusted.dy, size.width, size.height);
        if (newRect.overlaps(rect)) {
          adjusted = adjusted.translate(0, size.height + spacing);
          hasOverlap = true;
          break;
        }
      }
    } while (hasOverlap);

    return adjusted;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}