import 'dart:math';
import 'package:flutter/material.dart';

class CustomSpiderChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive dimensions
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 400;
        final isTinyScreen = screenWidth < 350;

        // Adjust chart radius based on screen size with better scaling
        final responsiveRadius = isTinyScreen
            ? min(screenWidth * 0.20, chartRadius * 0.6)
            : isSmallScreen
                ? min(screenWidth * 0.25, chartRadius * 0.75)
                : min(screenWidth * 0.28, chartRadius);

        // Calculate container size to accommodate labels with better spacing
        final labelSpacing = isTinyScreen
            ? 50
            : isSmallScreen
                ? 60
                : 80;
        final containerSize = (responsiveRadius * 2) + (labelSpacing * 2);

        return Container(
          width: double.infinity,
          height: containerSize,
          padding: EdgeInsets.all(isTinyScreen ? 8 : 12),
          child: Center(
            child: SizedBox(
              width: containerSize,
              height: containerSize,
              child: CustomPaint(
                painter: SpiderChartPainter(
                  data: data,
                  averageMap: averageMap,
                  chartRadius: responsiveRadius,
                  tickCount: tickCount,
                  screenWidth: screenWidth,
                  isSmallScreen: isSmallScreen,
                  isTinyScreen: isTinyScreen,
                  containerSize: containerSize,
                ),
                size: Size(containerSize, containerSize),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SpiderChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Map<String, double> averageMap;
  final double chartRadius;
  final int tickCount;
  final double screenWidth;
  final bool isSmallScreen;
  final bool isTinyScreen;
  final double containerSize;

  SpiderChartPainter({
    required this.data,
    required this.averageMap,
    required this.chartRadius,
    required this.tickCount,
    required this.screenWidth,
    required this.isSmallScreen,
    required this.isTinyScreen,
    required this.containerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Enhanced paint objects with better styling
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final Paint axisPaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final Paint dataPaint = Paint()
      ..color = Colors.deepPurple.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final Paint dataStrokePaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = isTinyScreen ? 1.5 : 2;

    final Paint averagePaint = Paint()
      ..color = Colors.orange.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final Paint averageStrokePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = isTinyScreen ? 1 : 1.5;

    // Draw concentric polygons (grid)
    for (int i = 1; i <= tickCount; i++) {
      final radius = (chartRadius / tickCount) * i;
      _drawPolygon(canvas, center, radius, data.length, gridPaint);
    }

    // Draw axes
    final angleStep = 2 * pi / data.length;
    for (int i = 0; i < data.length; i++) {
      final angle = -pi / 2 + i * angleStep;
      final endPoint = Offset(
        center.dx + chartRadius * cos(angle),
        center.dy + chartRadius * sin(angle),
      );
      canvas.drawLine(center, endPoint, axisPaint);
    }

    // Find max value for normalization
    final maxValue = data.map((d) => d['percent'] as double).reduce(max);
    final normalizedMax = maxValue > 0 ? maxValue : 100.0;

    // Draw average data polygon
    final averagePoints = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final condition = data[i]['condition'].toString().toLowerCase();
      final averageValue = averageMap[condition] ?? 50.0;
      final normalizedAverage = (averageValue / normalizedMax).clamp(0.0, 1.0);
      final radius = chartRadius * normalizedAverage;
      final angle = -pi / 2 + i * angleStep;

      averagePoints.add(Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      ));
    }

    if (averagePoints.isNotEmpty) {
      final averagePath = Path();
      averagePath.moveTo(averagePoints[0].dx, averagePoints[0].dy);
      for (int i = 1; i < averagePoints.length; i++) {
        averagePath.lineTo(averagePoints[i].dx, averagePoints[i].dy);
      }
      averagePath.close();
      canvas.drawPath(averagePath, averagePaint);
      canvas.drawPath(averagePath, averageStrokePaint);
    }

    // Draw actual data polygon
    final dataPoints = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final value = data[i]['percent'] as double;
      final normalizedValue = (value / normalizedMax).clamp(0.0, 1.0);
      final radius = chartRadius * normalizedValue;
      final angle = -pi / 2 + i * angleStep;

      dataPoints.add(Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      ));
    }

    if (dataPoints.isNotEmpty) {
      final dataPath = Path();
      dataPath.moveTo(dataPoints[0].dx, dataPoints[0].dy);
      for (int i = 1; i < dataPoints.length; i++) {
        dataPath.lineTo(dataPoints[i].dx, dataPoints[i].dy);
      }
      dataPath.close();
      canvas.drawPath(dataPath, dataPaint);
      canvas.drawPath(dataPath, dataStrokePaint);
    }

    // Draw data points with responsive sizes
    final pointSize = isTinyScreen
        ? 2.5
        : isSmallScreen
            ? 3.0
            : 4.0;
    for (final point in dataPoints) {
      canvas.drawCircle(point, pointSize, Paint()..color = Colors.deepPurple);
      canvas.drawCircle(
          point,
          pointSize + 1,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }

    for (final point in averagePoints) {
      canvas.drawCircle(point, pointSize * 0.8, Paint()..color = Colors.orange);
    }

    // Draw labels with enhanced responsive positioning
    _drawEnhancedResponsiveLabels(canvas, center, size);

    // Draw legend
    _drawLegend(canvas, size);
  }

  void _drawEnhancedResponsiveLabels(Canvas canvas, Offset center, Size size) {
    final angleStep = 2 * pi / data.length;

    // Calculate responsive label distance and font sizes
    final baseLabelDistance = chartRadius +
        (isTinyScreen
            ? 20
            : isSmallScreen
                ? 30
                : 40);
    final conditionFontSize = isTinyScreen
        ? 8.0
        : isSmallScreen
            ? 9.0
            : 11.0;
    final valueFontSize = isTinyScreen
        ? 7.0
        : isSmallScreen
            ? 8.0
            : 10.0;

    // Store label positions to avoid overlaps
    final List<Rect> usedRects = [];

    for (int i = 0; i < data.length; i++) {
      final angle = -pi / 2 + i * angleStep;
      final condition = data[i]['condition'].toString();
      final value = data[i]['percent'] as double;

      // Format condition name based on screen size
      final formattedCondition = _formatConditionNameEnhanced(condition);

      // Create text painters with responsive styling
      final conditionTextPainter = TextPainter(
        text: TextSpan(
          text: formattedCondition,
          style: TextStyle(
            color: Colors.black87,
            fontSize: conditionFontSize,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: isTinyScreen ? 2 : 1,
        textAlign: TextAlign.center,
      );

      final valueTextPainter = TextPainter(
        text: TextSpan(
          text: '${value.toStringAsFixed(0)}%',
          style: TextStyle(
            color: Colors.deepPurple,
            fontSize: valueFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      conditionTextPainter.layout(maxWidth: isTinyScreen ? 60 : 80);
      valueTextPainter.layout();

      // Calculate optimal label position
      final labelPosition = _calculateOptimalLabelPosition(
        center,
        angle,
        baseLabelDistance,
        conditionTextPainter,
        valueTextPainter,
        size,
        usedRects,
      );

      // Draw background for better readability
      final totalHeight =
          conditionTextPainter.height + valueTextPainter.height + 4;
      final maxWidth = max(conditionTextPainter.width, valueTextPainter.width);

      final backgroundRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: labelPosition,
          width: maxWidth + 8,
          height: totalHeight + 4,
        ),
        Radius.circular(4),
      );

      canvas.drawRRect(
        backgroundRect,
        Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..style = PaintingStyle.fill,
      );

      canvas.drawRRect(
        backgroundRect,
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );

      // Draw condition name
      final conditionOffset = Offset(
        labelPosition.dx - conditionTextPainter.width / 2,
        labelPosition.dy - totalHeight / 2 + 2,
      );
      conditionTextPainter.paint(canvas, conditionOffset);

      // Draw value
      final valueOffset = Offset(
        labelPosition.dx - valueTextPainter.width / 2,
        labelPosition.dy - totalHeight / 2 + conditionTextPainter.height + 4,
      );
      valueTextPainter.paint(canvas, valueOffset);

      // Draw subtle connection line
      final connectionStart = Offset(
        center.dx + chartRadius * cos(angle),
        center.dy + chartRadius * sin(angle),
      );

      // Only draw connection line if label is far from chart
      final distance = (labelPosition - connectionStart).distance;
      if (distance > chartRadius * 0.3) {
        final connectionPaint = Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..strokeWidth = 0.5;

        canvas.drawLine(connectionStart, labelPosition, connectionPaint);
      }

      // Add used rect to avoid overlaps
      usedRects.add(backgroundRect.outerRect);
    }
  }

  String _formatConditionNameEnhanced(String condition) {
    // Enhanced condition name formatting with better abbreviations
    final Map<String, String> conditionMappings = {
      'nasolabial fold': isTinyScreen ? 'Nasolabial' : 'Nasolabial Fold',
      'dark circle': isTinyScreen ? 'Dark\nCircles' : 'Dark Circle',
      'eye bag': isTinyScreen ? 'Eye\nBags' : 'Eye Bag',
      'brown spot': isTinyScreen ? 'Brown\nSpots' : 'Brown Spot',
      'dark spot': isTinyScreen ? 'Dark\nSpots' : 'Dark Spot',
      'pigmentation': isTinyScreen ? 'Pigment' : 'Pigmentation',
      'blackhead': isTinyScreen ? 'Black\nheads' : 'Blackhead',
      'comedone': isTinyScreen ? 'Come\ndone' : 'Comedone',
      'wrinkle': 'Wrinkles',
      'pores': 'Pores',
      'acne': 'Acne',
      'mole': 'Mole',
      'normal': 'Normal',
    };

    final lowerCondition = condition.toLowerCase();

    if (conditionMappings.containsKey(lowerCondition)) {
      return conditionMappings[lowerCondition]!;
    }

    // Fallback formatting
    final words = condition.split(' ');
    if (isTinyScreen && words.length > 1) {
      return words
          .map(
              (word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
          .join('\n');
    }

    return words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Offset _calculateOptimalLabelPosition(
    Offset center,
    double angle,
    double baseDistance,
    TextPainter conditionPainter,
    TextPainter valuePainter,
    Size canvasSize,
    List<Rect> usedRects,
  ) {
    final maxTextWidth = max(conditionPainter.width, valuePainter.width);
    final totalTextHeight = conditionPainter.height + valuePainter.height + 4;

    // Start with base position
    double labelDistance = baseDistance;
    Offset labelPosition;

    // Try different distances to avoid overlaps and boundaries
    for (int attempt = 0; attempt < 5; attempt++) {
      labelDistance += attempt * 10;

      labelPosition = Offset(
        center.dx + labelDistance * cos(angle),
        center.dy + labelDistance * sin(angle),
      );

      // Adjust for canvas boundaries with padding
      final padding = isTinyScreen ? 15.0 : 20.0;
      labelPosition = Offset(
        labelPosition.dx.clamp(
          maxTextWidth / 2 + padding,
          canvasSize.width - maxTextWidth / 2 - padding,
        ),
        labelPosition.dy.clamp(
          totalTextHeight / 2 + padding,
          canvasSize.height - totalTextHeight / 2 - padding,
        ),
      );

      // Check for overlaps with existing labels
      final proposedRect = Rect.fromCenter(
        center: labelPosition,
        width: maxTextWidth + 12,
        height: totalTextHeight + 8,
      );

      bool hasOverlap = false;
      for (final usedRect in usedRects) {
        if (proposedRect.overlaps(usedRect)) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        return labelPosition;
      }
    }

    // Fallback: return adjusted position even with potential overlap
    return Offset(
      center.dx + baseDistance * cos(angle),
      center.dy + baseDistance * sin(angle),
    );
  }

  void _drawLegend(Canvas canvas, Size size) {
    if (isTinyScreen) return; // Skip legend on very small screens

    final legendY = size.height - (isSmallScreen ? 15 : 20);
    final legendStartX = size.width * 0.1;

    // Your data legend
    canvas.drawCircle(
      Offset(legendStartX, legendY),
      isSmallScreen ? 3 : 4,
      Paint()..color = Colors.deepPurple,
    );

    final yourDataPainter = TextPainter(
      text: TextSpan(
        text: 'Your Data',
        style: TextStyle(
          color: Colors.black87,
          fontSize: isSmallScreen ? 9 : 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    yourDataPainter.layout();
    yourDataPainter.paint(
      canvas,
      Offset(legendStartX + 15, legendY - yourDataPainter.height / 2),
    );

    // Average legend
    final avgLegendX = legendStartX + yourDataPainter.width + 40;
    canvas.drawCircle(
      Offset(avgLegendX, legendY),
      isSmallScreen ? 3 : 4,
      Paint()..color = Colors.orange,
    );

    final avgDataPainter = TextPainter(
      text: TextSpan(
        text: 'Average',
        style: TextStyle(
          color: Colors.black87,
          fontSize: isSmallScreen ? 9 : 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    avgDataPainter.layout();
    avgDataPainter.paint(
      canvas,
      Offset(avgLegendX + 15, legendY - avgDataPainter.height / 2),
    );
  }

  void _drawPolygon(
      Canvas canvas, Offset center, double radius, int sides, Paint paint) {
    final path = Path();
    final angleStep = 2 * pi / sides;

    for (int i = 0; i < sides; i++) {
      final angle = -pi / 2 + i * angleStep;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
