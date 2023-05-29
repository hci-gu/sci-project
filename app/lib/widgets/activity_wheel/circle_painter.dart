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
    this.strokeWidth = 9,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double max = items.map((e) => e.value).reduce(math.max);
    double minValue = max * 0.05;

    final center = size.center(Offset.zero);
    final radius = chartRadius - strokeWidth * 0.5;

    final totalValue =
        items.fold<double>(0, (a, b) => a + math.max(b.value, minValue));
    final totalRad =
        (animationValue * math.pi * 2) - ((items.length - 1) * 0.15);
    double startAngle = 0;

    for (var item in items) {
      var sweepAngle = totalRad *
          item.animationValue *
          math.max(item.value, minValue) /
          totalValue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.175,
        false,
        Paint()
          ..color = item.color
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      startAngle += sweepAngle + 0.1;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
