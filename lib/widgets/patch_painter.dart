import 'package:flutter/material.dart';
import '../models/skin_analysis_model.dart';
import 'dart:math';

const Map<SkinIssueType, Color> issueColors = {
  SkinIssueType.acne: Colors.red,
  SkinIssueType.closedComedone: Colors.orange,
  SkinIssueType.brownSpot: Colors.brown,
  SkinIssueType.melasma: Colors.purple,
  SkinIssueType.freckle: Colors.amber,
  SkinIssueType.mole: Colors.black,
  SkinIssueType.acnePustule: Colors.pink,
  SkinIssueType.acneNodule: Colors.indigo,
  SkinIssueType.acneMark: Colors.blueGrey,
  SkinIssueType.darkCircle: Colors.blue,
  SkinIssueType.wrinkle: Colors.green,
  SkinIssueType.eyePouch: Colors.teal,
  SkinIssueType.nasolabialFold: Colors.deepOrange,
};

class PatchPainter extends CustomPainter {
  final List<SkinPatch> patches;
  final Size originalImageSize;
  final Size displaySize;
  final SkinIssueType? selectedType;
  final bool seeAll; // If true, shows all overlays

  PatchPainter(
    this.patches, {
    required this.originalImageSize,
    required this.displaySize,
    this.selectedType,
    this.seeAll = false,
  });

  static const List<double> arrowAngles = [
    -pi / 2,
    -pi / 3,
    -pi / 4,
    -pi / 6,
    0,
    pi / 6,
    pi / 4,
    pi / 3,
    pi / 2,
    2 * pi / 3,
    3 * pi / 4,
    5 * pi / 6,
    pi,
    -5 * pi / 6,
    -3 * pi / 4,
    -2 * pi / 3,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = displaySize.width / originalImageSize.width;
    final scaleY = displaySize.height / originalImageSize.height;

    // Group patches by issueType
    final Map<SkinIssueType, List<SkinPatch>> grouped = {};
    for (final patch in patches) {
      if (patch.issueType == SkinIssueType.unknown) continue;
      if (!seeAll && selectedType != null && patch.issueType != selectedType)
        continue;
      grouped.putIfAbsent(patch.issueType, () => []).add(patch);
    }

    int typeIdx = 0;
    for (final entry in grouped.entries) {
      final issueType = entry.key;
      final group = entry.value;
      final color = issueColors[issueType] ?? Colors.grey;

      // Paint for dots and arrows
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final arrowPaint = Paint()
        ..color = color
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke;

      final fillPaint = Paint()
        ..color = color.withOpacity(0.18)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke;

      double angle = arrowAngles[typeIdx % arrowAngles.length];
      typeIdx++;

      // If more than 6, show multiple dots, ONE arrow and patch at centroid
      if (group.length > 6) {
        final List<Offset> dotCenters = [];
        for (final patch in group) {
          Offset center = _getPatchCenter(patch, scaleX, scaleY);
          if (center != Offset.zero) {
            dotCenters.add(center);
            canvas.drawCircle(center, 6, dotPaint);
          }
        }
        if (dotCenters.isEmpty) continue;
        // Compute centroid
        final centroid = Offset(
          dotCenters.map((e) => e.dx).reduce((a, b) => a + b) /
              dotCenters.length,
          dotCenters.map((e) => e.dy).reduce((a, b) => a + b) /
              dotCenters.length,
        );
        // Arrow from centroid
        double arrowLen = 75.0;
        Offset arrowVector = Offset(cos(angle), sin(angle));
        Offset arrowEnd = centroid + arrowVector * arrowLen;

        _drawArrow(canvas, centroid, arrowEnd, arrowPaint);

        // Use average patch size for patch at arrow tip
        double avgW = 0, avgH = 0, cnt = 0;
        for (final patch in group) {
          var sz = _getPatchSize(patch, scaleX, scaleY);
          avgW += sz.width;
          avgH += sz.height;
          cnt++;
        }
        avgW = max(36, avgW / cnt * 0.8);
        avgH = max(22, avgH / cnt * 0.6);

        final patchRect = Rect.fromCenter(
          center: arrowEnd,
          width: avgW,
          height: avgH,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(patchRect, Radius.circular(8)),
          fillPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(patchRect, Radius.circular(8)),
          borderPaint,
        );
        _drawLabel(
            canvas, patchRect, skinIssueTypeDisplayName(issueType), color);
      }
      // If 5 or fewer, show arrow+patch+label for each
      else if (group.length <= 5) {
        for (final patch in group) {
          Offset center = _getPatchCenter(patch, scaleX, scaleY);
          if (center == Offset.zero) continue;

          double arrowLen = 75.0;
          Offset arrowVector = Offset(cos(angle), sin(angle));
          Offset arrowEnd = center + arrowVector * arrowLen;

          canvas.drawCircle(center, 6, dotPaint);
          _drawArrow(canvas, center, arrowEnd, arrowPaint);

          var sz = _getPatchSize(patch, scaleX, scaleY);
          double patchW = max(36, sz.width * 0.9);
          double patchH = max(22, sz.height * 0.7);

          final patchRect = Rect.fromCenter(
            center: arrowEnd,
            width: patchW,
            height: patchH,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(patchRect, Radius.circular(8)),
            fillPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(patchRect, Radius.circular(8)),
            borderPaint,
          );
          _drawLabel(
              canvas, patchRect, skinIssueTypeDisplayName(issueType), color);
        }
      }
      // For 6 exactly, can use either approach; here treat same as >6
      else if (group.length == 6) {
        final List<Offset> dotCenters = [];
        for (final patch in group) {
          Offset center = _getPatchCenter(patch, scaleX, scaleY);
          if (center != Offset.zero) {
            dotCenters.add(center);
            canvas.drawCircle(center, 6, dotPaint);
          }
        }
        if (dotCenters.isEmpty) continue;
        final centroid = Offset(
          dotCenters.map((e) => e.dx).reduce((a, b) => a + b) /
              dotCenters.length,
          dotCenters.map((e) => e.dy).reduce((a, b) => a + b) /
              dotCenters.length,
        );
        double arrowLen = 75.0;
        Offset arrowVector = Offset(cos(angle), sin(angle));
        Offset arrowEnd = centroid + arrowVector * arrowLen;

        _drawArrow(canvas, centroid, arrowEnd, arrowPaint);

        double avgW = 0, avgH = 0, cnt = 0;
        for (final patch in group) {
          var sz = _getPatchSize(patch, scaleX, scaleY);
          avgW += sz.width;
          avgH += sz.height;
          cnt++;
        }
        avgW = max(36, avgW / cnt * 0.8);
        avgH = max(22, avgH / cnt * 0.6);

        final patchRect = Rect.fromCenter(
          center: arrowEnd,
          width: avgW,
          height: avgH,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(patchRect, Radius.circular(8)),
          fillPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(patchRect, Radius.circular(8)),
          borderPaint,
        );
        _drawLabel(
            canvas, patchRect, skinIssueTypeDisplayName(issueType), color);
      }
    }
  }

  Offset _getPatchCenter(SkinPatch patch, double scaleX, double scaleY) {
    if (patch.rect != null) {
      final rect = Rect.fromLTWH(
        patch.rect!.left * scaleX,
        patch.rect!.top * scaleY,
        patch.rect!.width * scaleX,
        patch.rect!.height * scaleY,
      );
      return rect.center;
    } else if (patch.polygon != null && patch.polygon!.isNotEmpty) {
      double sumX = 0, sumY = 0;
      for (final pt in patch.polygon!) {
        sumX += pt.dx * scaleX;
        sumY += pt.dy * scaleY;
      }
      return Offset(sumX / patch.polygon!.length, sumY / patch.polygon!.length);
    }
    return Offset.zero;
  }

  Size _getPatchSize(SkinPatch patch, double scaleX, double scaleY) {
    if (patch.rect != null) {
      return Size(patch.rect!.width * scaleX, patch.rect!.height * scaleY);
    } else if (patch.polygon != null && patch.polygon!.isNotEmpty) {
      double minX = double.infinity,
          minY = double.infinity,
          maxX = double.negativeInfinity,
          maxY = double.negativeInfinity;
      for (final pt in patch.polygon!) {
        final px = pt.dx * scaleX, py = pt.dy * scaleY;
        if (px < minX) minX = px;
        if (py < minY) minY = py;
        if (px > maxX) maxX = px;
        if (py > maxY) maxY = py;
      }
      return Size(maxX - minX, maxY - minY);
    }
    return const Size(40, 24);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint arrowPaint) {
    canvas.drawLine(start, end, arrowPaint);

    // Arrowhead
    const double arrowHeadLength = 9;
    const double arrowHeadAngle = 0.5;
    final angle = (end - start).direction;
    final arrowP1 =
        end + Offset.fromDirection(angle + arrowHeadAngle, -arrowHeadLength);
    final arrowP2 =
        end + Offset.fromDirection(angle - arrowHeadAngle, -arrowHeadLength);
    canvas.drawLine(end, arrowP1, arrowPaint);
    canvas.drawLine(end, arrowP2, arrowPaint);
  }

  void _drawLabel(Canvas canvas, Rect patchRect, String text, Color bgColor) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        backgroundColor: Colors.transparent,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    tp.layout();

    Offset labelOffset = Offset(
      patchRect.center.dx - tp.width / 2,
      patchRect.top - tp.height - 5,
    );

    final bgRect = Rect.fromLTWH(
      labelOffset.dx - 4,
      labelOffset.dy - 1,
      tp.width + 8,
      tp.height + 4,
    );
    final paint = Paint()..color = bgColor.withOpacity(0.85);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, Radius.circular(6)), paint);

    tp.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant PatchPainter oldDelegate) {
    return oldDelegate.patches != patches ||
        oldDelegate.selectedType != selectedType ||
        oldDelegate.originalImageSize != originalImageSize ||
        oldDelegate.displaySize != displaySize ||
        oldDelegate.seeAll != seeAll;
  }
}
