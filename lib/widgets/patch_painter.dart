import 'package:flutter/material.dart';
import '../models/skin_analysis_model.dart';

// Assign color per type, you can customize!
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

  PatchPainter(
    this.patches, {
    required this.originalImageSize,
    required this.displaySize,
    this.selectedType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = displaySize.width / originalImageSize.width;
    final scaleY = displaySize.height / originalImageSize.height;

    bool singleLabelDrawn = false;

    for (final patch in patches) {
      final type = patch.issueType;
      if (selectedType != null && type != selectedType) continue;

      final color = selectedType == null
          ? (issueColors[type] ?? Colors.grey)
          : (selectedType == type
              ? Colors.blue
              : (issueColors[type] ?? Colors.grey).withOpacity(0.4));

      final paint = Paint()
        ..color = color.withOpacity(
            selectedType == null ? 0.5 : (selectedType == type ? 0.7 : 0.2))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      if (patch.rect != null) {
        final rect = Rect.fromLTWH(
          patch.rect!.left * scaleX,
          patch.rect!.top * scaleY,
          patch.rect!.width * scaleX,
          patch.rect!.height * scaleY,
        );
        canvas.drawRect(rect, paint);

        // By default: show all names; when filtered, show only one name for that type
        if (selectedType == null) {
          _drawLabel(canvas, rect.topLeft, skinIssueTypeDisplayName(type), rect,
              color);
        } else if (selectedType == type && !singleLabelDrawn) {
          _drawLabel(canvas, rect.topLeft, skinIssueTypeDisplayName(type), rect,
              color);
          singleLabelDrawn = true;
        }
      } else if (patch.polygon != null && patch.polygon!.isNotEmpty) {
        final path = Path();
        for (int i = 0; i < patch.polygon!.length; i++) {
          final pt = patch.polygon![i];
          final offset = Offset(pt.dx * scaleX, pt.dy * scaleY);
          if (i == 0) {
            path.moveTo(offset.dx, offset.dy);
          } else {
            path.lineTo(offset.dx, offset.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);

        if (selectedType == null) {
          final labelOffset =
              _polygonLabelOffset(patch.polygon!, scaleX, scaleY);
          _drawLabel(
              canvas, labelOffset, skinIssueTypeDisplayName(type), null, color);
        } else if (selectedType == type && !singleLabelDrawn) {
          final labelOffset =
              _polygonLabelOffset(patch.polygon!, scaleX, scaleY);
          _drawLabel(
              canvas, labelOffset, skinIssueTypeDisplayName(type), null, color);
          singleLabelDrawn = true;
        }
      }
      // Do not draw anything for patches with no location (rect/polygon == null)
    }
  }

  Offset _polygonLabelOffset(
      List<Offset> polygon, double scaleX, double scaleY) {
    double sumX = 0, sumY = 0;
    for (final pt in polygon) {
      sumX += pt.dx * scaleX;
      sumY += pt.dy * scaleY;
    }
    return Offset(sumX / polygon.length, sumY / polygon.length - 16);
  }

  void _drawLabel(
      Canvas canvas, Offset position, String text, Rect? rect, Color bgColor) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        backgroundColor: bgColor.withOpacity(0.9),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final labelOffset = rect != null
        ? Offset(position.dx, position.dy - tp.height - 4)
        : position;

    final bgRect = Rect.fromLTWH(
      labelOffset.dx,
      labelOffset.dy,
      tp.width + 8,
      tp.height + 4,
    );
    final bgPaint = Paint()..color = bgColor.withOpacity(0.9);
    canvas.drawRect(bgRect, bgPaint);

    tp.paint(canvas, labelOffset + const Offset(4, 2));
  }

  @override
  bool shouldRepaint(covariant PatchPainter oldDelegate) {
    return oldDelegate.patches != patches ||
        oldDelegate.selectedType != selectedType ||
        oldDelegate.originalImageSize != originalImageSize ||
        oldDelegate.displaySize != displaySize;
  }
}
