import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ArrDepChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  ArrDepChartPainter(this.data);

  final List<Color> yearColors = [
    Colors.green, // 2023
    Colors.red,   // 2024
    Colors.blue,  // 2025
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final double margin = 40;
    final double chartWidth = size.width - margin * 2;
    final double chartHeight = size.height - margin;

    // Extract the max value for scaling
    double maxY = 0;
    for (var entry in data) {
      for (var key in ['2023', '2024', '2025']) {
        if (entry.containsKey(key) && entry[key] is num) {
          maxY = maxY < entry[key] ? entry[key].toDouble() : maxY;
        }
      }
    }
    if (maxY < 1) return;

    int pointCount = data.length;
    double dx = chartWidth / (pointCount - 1);

    for (int i = 0; i < 3; i++) {
      String year = (2023 + i).toString();
      Path path = Path();
      List<Offset> points = [];

      for (int j = 0; j < pointCount; j++) {
        final entry = data[j];
        double x = margin + dx * j;
        double yValue = entry[year]?.toDouble() ?? 0;
        double y = margin + chartHeight * (1 - yValue / maxY);
        points.add(Offset(x, y));
      }

      paint.color = yearColors[i];
      _drawDashedPath(canvas, pathFromPoints(points), paint);

      for (int j = 0; j < points.length; j++) {
        canvas.drawCircle(points[j], 3, Paint()..color = yearColors[i]);
        canvas.drawCircle(points[j], 4, Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
      }

      // Label the "Present" point for 2025
      if (year == '2025') {
        final presentPoint = points.length > 6 ? points[6] : points.last;
        final textSpan = TextSpan(
          text: 'Present',
          style: TextStyle(color: yearColors[i], fontSize: 10),
        );
        final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(presentPoint.dx + 4, presentPoint.dy - 14));
      }
    }
  }

  Path pathFromPoints(List<Offset> points) {
    Path path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);
    for (var point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 6;
    const dashSpace = 4;
    final PathMetrics pathMetrics = path.computeMetrics();
    for (final PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          pathMetric.extractPath(distance, next),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
