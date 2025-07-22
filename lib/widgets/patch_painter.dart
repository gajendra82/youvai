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

  final double _lineLength = 35;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final scaleX = displaySize.width / imageSize.width;
    final scaleY = displaySize.height / imageSize.height;

    // Group patches by issue type
    final Map<SkinIssueType, List<SkinPatch>> grouped = {};
    for (final patch in patches) {
      if (patch.issueType == SkinIssueType.unknown) continue;
      grouped.putIfAbsent(patch.issueType, () => []).add(patch);
    }

    int leftIndex = 0;
    int rightIndex = 0;

    for (final entry in grouped.entries) {
      final type = entry.key;
      final patchList = entry.value;

      final color = _getColorForIssue(type);
      paint.color = color;

      Offset? labelPosition;

      for (int i = 0; i < patchList.length; i++) {
        final patch = patchList[i];

        Offset centroid;
        if (patch.rect != null) {
          final r = patch.rect!;
          centroid = Offset(
            (r.left + r.right) / 2 * scaleX,
            (r.top + r.bottom) / 2 * scaleY,
          );
          _drawLCorners(
              canvas,
              Rect.fromLTRB(
                r.left * scaleX,
                r.top * scaleY,
                r.right * scaleX,
                r.bottom * scaleY,
              ),
              paint);
        } else if (patch.polygon != null && patch.polygon!.isNotEmpty) {
          final polygon = patch.polygon!;
          final scaled = polygon
              .map((pt) => Offset(pt.dx * scaleX, pt.dy * scaleY))
              .toList();
          centroid = _calculateCentroid(scaled);
          final path = Path()..addPolygon(scaled, true);
          canvas.drawPath(path, paint);
        } else {
          continue;
        }

        _drawStartMarker(canvas, centroid, color);

        // For more than 6 patches of the same type, draw label only once
        bool shouldDrawLabel = patchList.length <= 6 || i == 0;
        if (shouldDrawLabel) {
          final isLeft = centroid.dx < displaySize.width / 2;
          final horizontalOffset = isLeft ? -_lineLength : _lineLength;
          final intermediate =
              Offset(centroid.dx + horizontalOffset, centroid.dy);
          final labelOffset = Offset(
            intermediate.dx + (isLeft ? -5 : 5),
            intermediate.dy +
                (isLeft ? leftIndex++ * 20.0 : rightIndex++ * 20.0),
          );

          _drawLShapedLine(canvas, centroid, intermediate, labelOffset, paint);
          _drawLabel(canvas, labelOffset, type, color, isLeft);
        }
      }
    }
  }

  void _drawStartMarker(Canvas canvas, Offset center, Color color) {
    const double size = 12;
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    final fillPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);

    final plusPaint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    final double half = size / 2.2;
    canvas.drawLine(
      Offset(center.dx - half + 1, center.dy),
      Offset(center.dx + half - 1, center.dy),
      plusPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - half + 1),
      Offset(center.dx, center.dy + half - 1),
      plusPaint,
    );
  }

  void _drawLShapedLine(
      Canvas canvas, Offset start, Offset bend, Offset end, Paint paint) {
    canvas.drawLine(start, bend, paint);
    canvas.drawLine(bend, end, paint);
  }

  void _drawLabel(
      Canvas canvas, Offset pos, SkinIssueType type, Color color, bool isLeft) {
    const double radius = 8;
    final circleOffset = Offset(
      isLeft ? pos.dx - radius - 2 : pos.dx + radius + 2,
      pos.dy,
    );
    final textOffset = Offset(
      isLeft ? pos.dx - 70 : pos.dx + 12,
      pos.dy - 7,
    );

    final circlePaint = Paint()..color = color;
    canvas.drawCircle(circleOffset, radius, circlePaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: skinIssueTypeDisplayName(type),
        style: TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, textOffset);
  }

  void _drawLCorners(Canvas canvas, Rect rect, Paint paint) {
    const double cornerLength = 12;
    // Top-left
    canvas.drawLine(
        rect.topLeft, rect.topLeft + Offset(cornerLength, 0), paint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft + Offset(0, cornerLength), paint);
    // Top-right
    canvas.drawLine(
        rect.topRight, rect.topRight + Offset(-cornerLength, 0), paint);
    canvas.drawLine(
        rect.topRight, rect.topRight + Offset(0, cornerLength), paint);
    // Bottom-left
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + Offset(cornerLength, 0), paint);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + Offset(0, -cornerLength), paint);
    // Bottom-right
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight + Offset(-cornerLength, 0), paint);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight + Offset(0, -cornerLength), paint);
  }

  Offset _calculateCentroid(List<Offset> points) {
    double x = 0, y = 0;
    for (final pt in points) {
      x += pt.dx;
      y += pt.dy;
    }
    return Offset(x / points.length, y / points.length);
  }

  Color _getColorForIssue(SkinIssueType type) {
    switch (type) {
      case SkinIssueType.acne:
        return Colors.red;
      case SkinIssueType.closedComedone:
        return Colors.orange;
      case SkinIssueType.brownSpot:
        return Colors.brown;
      case SkinIssueType.melasma:
        return Colors.deepPurple;
      case SkinIssueType.freckle:
        return Colors.amber;
      case SkinIssueType.mole:
        return Colors.black;
      case SkinIssueType.acnePustule:
        return Colors.pink;
      case SkinIssueType.acneNodule:
        return Colors.teal;
      case SkinIssueType.acneMark:
        return Colors.indigo;
      case SkinIssueType.darkCircle:
        return Colors.blueGrey;
      case SkinIssueType.wrinkle:
        return Colors.grey;
      case SkinIssueType.eyePouch:
        return Colors.lightGreen;
      case SkinIssueType.nasolabialFold:
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant PatchPainter oldDelegate) {
    return oldDelegate.patches != patches ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.displaySize != displaySize ||
        oldDelegate.selectedType != selectedType;
  }
}
