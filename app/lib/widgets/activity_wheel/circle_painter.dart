import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircleChartItem {
  final double value;
  final double animationValue;
  final Color color;

  CircleChartItem({
    required this.value,
    required this.color,
    this.animationValue = 1,
  });
}

class CirclePainter extends CustomPainter {
  final double chartRadius;
  final List<CircleChartItem> items;
  final double strokeWidth;
  final double animationValue;

  const CirclePainter({
    required this.chartRadius,
    required this.items,
    this.strokeWidth = 17.5,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = chartRadius - strokeWidth * 0.5;
    final totalValue = items.fold<double>(0, (a, b) => a + b.value);
    final totalRad = animationValue * math.pi * 2;
    double startAngle = 0;

    /// draw circle background
    // canvas.drawCircle(
    //     center,
    //     radius,
    //     Paint()
    //       ..color = Colors.black54
    //       ..strokeWidth = circleStrokeWidth
    //       ..strokeCap = StrokeCap.round
    //       ..strokeJoin = StrokeJoin.round
    //       ..style = PaintingStyle.stroke);

    for (var item in items) {
      var sweepAngle =
          totalRad * 0.86 * item.animationValue * item.value / totalValue;
      var offset =
          totalRad * 0.075 * item.animationValue * item.value / totalValue;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          Paint()
            ..color = item.color
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke);
      startAngle += sweepAngle + (offset * (items.indexOf(item) + 1));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
