import 'dart:math';
import 'package:flutter/material.dart';

class CustomSpiderChart extends StatelessWidget {
  final List<Map<String, dynamic>> data; // {condition: String, percent: double}
  final Map<String, double> averageMap;
  final double chartRadius;
  final int tickCount;

  const CustomSpiderChart({
    Key? key,
    required this.data,
    required this.averageMap,
    this.chartRadius = 120.0,
    this.tickCount = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6.0, left: 6.0),
          child: Text(
            "Spider Chart of Condition Percentages",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: chartRadius * 2 + 60, // Extra width for labels outside
          height: chartRadius * 2 + 60, // Extra height for labels outside
          child: CustomPaint(
            painter: SpiderChartPainter(
              data: data,
              averageMap: averageMap,
              chartRadius: chartRadius,
              tickCount: tickCount,
            ),
            child: Container(),
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(top: 6.0, left: 6.0),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: Colors.green),
              const SizedBox(width: 6),
              const Text("Your strengths", style: TextStyle(fontSize: 13)),
              const SizedBox(width: 12),
              Container(width: 16, height: 16, color: Colors.red),
              const SizedBox(width: 6),
              const Text("Your concerns", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class SpiderChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Map<String, double> averageMap;
  final double chartRadius;
  final int tickCount;

  SpiderChartPainter({
    required this.data,
    required this.averageMap,
    required this.chartRadius,
    required this.tickCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final int axisCount = data.length;
    final double maxValue = 100.0;
    final double angleStep = 2 * pi / axisCount;

    // Draw spider web (polygonal grid)
    for (int t = 1; t <= tickCount; t++) {
      final double r = chartRadius * (t / tickCount);
      final Path webPath = Path();
      for (int i = 0; i < axisCount; i++) {
        final double angle = angleStep * i - pi / 2;
        final Offset pt = Offset(
          center.dx + r * cos(angle),
          center.dy + r * sin(angle),
        );
        if (i == 0) {
          webPath.moveTo(pt.dx, pt.dy);
        } else {
          webPath.lineTo(pt.dx, pt.dy);
        }
      }
      webPath.close();
      final Paint webPaint = Paint()
        ..color = Colors.grey.shade700.withOpacity(t == tickCount ? 0.8 : 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = t == tickCount ? 2.5 : 1.0;
      canvas.drawPath(webPath, webPaint);

      // Tick labels (show only top center for clarity)
      if (axisCount > 0 && t > 0) {
        final double topAngle = -pi / 2;
        final Offset topPt = Offset(
          center.dx + r * cos(topAngle),
          center.dy + r * sin(topAngle),
        );
        final tp = TextPainter(
          text: TextSpan(
            text: "${(maxValue * t / tickCount).toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: t == tickCount ? FontWeight.bold : FontWeight.w400,
              shadows: [
                const Shadow(
                  color: Colors.black,
                  offset: Offset(0, 0),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, topPt + Offset(-tp.width / 2, -18));
      }
    }

    // Draw axes (lines from center)
    for (int i = 0; i < axisCount; i++) {
      final double angle = angleStep * i - pi / 2;
      final Offset axisEnd = Offset(
        center.dx + chartRadius * cos(angle),
        center.dy + chartRadius * sin(angle),
      );
      final Paint axisPaint = Paint()
        ..color = Colors.grey.shade700
        ..strokeWidth = 1.7;
      canvas.drawLine(center, axisEnd, axisPaint);
    }

    // Draw polygon for values (the spider, not a closed circle)
    Path spiderPath = Path();
    List<Offset> valuePoints = [];
    for (int i = 0; i < axisCount; i++) {
      final double angle = angleStep * i - pi / 2;
      final double value = data[i]['percent'] as double;
      final double valueRadius = chartRadius * (value / maxValue);
      final Offset pt = Offset(
        center.dx + valueRadius * cos(angle),
        center.dy + valueRadius * sin(angle),
      );
      valuePoints.add(pt);
      if (i == 0) {
        spiderPath.moveTo(pt.dx, pt.dy);
      } else {
        spiderPath.lineTo(pt.dx, pt.dy);
      }
    }
    final Paint spiderPaint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.19)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(spiderPath, spiderPaint);

    // Draw lines from center to value points (spider legs)
    for (final pt in valuePoints) {
      final Paint legPaint = Paint()
        ..color = Colors.blueAccent.withOpacity(0.7)
        ..strokeWidth = 2.5;
      canvas.drawLine(center, pt, legPaint);
    }

    // Draw colored dots and labels at each value point
    for (int i = 0; i < axisCount; i++) {
      final double angle = angleStep * i - pi / 2;
      final double value = data[i]['percent'] as double;
      final String label = data[i]['condition'];
      final bool isConcern = value > (averageMap[label.toLowerCase()] ?? 20.0);

      final Offset pt = valuePoints[i];

      // Dot color: green if strength, red if concern
      final Paint dotPaint = Paint()
        ..color = isConcern ? Colors.red : Colors.green;
      canvas.drawCircle(pt, 8, dotPaint);
      canvas.drawCircle(
        pt,
        8,
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Value label
      final tp = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 0)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pt + Offset(-tp.width / 2, -22));

      // Axis label - place further out, with more margin and no overlap
      final double labelDist = chartRadius + 30;
      final Offset labelPt = Offset(
        center.dx + labelDist * cos(angle),
        center.dy + labelDist * sin(angle),
      );

      // Calculate label alignment based on angle for better distribution
      Alignment align;
      if (angle >= -pi / 2 - 0.2 && angle <= -pi / 2 + 0.2) {
        align = Alignment.topCenter;
      } else if (angle > -pi / 2 && angle < pi / 2) {
        align = Alignment.centerRight;
      } else if (angle > pi / 2 || angle < -pi / 2) {
        align = Alignment.centerLeft;
      } else if ((angle - pi).abs() < 0.2) {
        align = Alignment.bottomCenter;
      } else {
        align = Alignment.center;
      }

      final labelText = label;
      final labelTp = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isConcern ? Colors.red : Colors.green,
            shadows: [
              Shadow(color: Colors.white, blurRadius: 6),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Use Offset based on alignment
      Offset labelOffset;
      if (align == Alignment.topCenter) {
        labelOffset = Offset(-labelTp.width / 2, -labelTp.height - 8);
      } else if (align == Alignment.bottomCenter) {
        labelOffset = Offset(-labelTp.width / 2, 8);
      } else if (align == Alignment.centerRight) {
        labelOffset = Offset(4, -labelTp.height / 2);
      } else if (align == Alignment.centerLeft) {
        labelOffset = Offset(-labelTp.width - 4, -labelTp.height / 2);
      } else {
        labelOffset = Offset(-labelTp.width / 2, -labelTp.height / 2);
      }

      labelTp.paint(
        canvas,
        labelPt + labelOffset,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpiderChartPainter oldDelegate) => true;
}
