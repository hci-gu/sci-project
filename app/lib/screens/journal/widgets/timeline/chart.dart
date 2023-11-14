import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/screens/demo/demo.dart';
import 'package:scimovement/theme/theme.dart';

double getRandomInt(int min, int max) {
  return min + Random().nextInt(max - min).toDouble();
}

class TimelineChart extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final List<PainLevelEntry> entries;

  const TimelineChart({
    super.key,
    required this.start,
    required this.end,
    this.entries = const [],
  });

  @override
  Widget build(BuildContext context) {
    List<BodyPart> bodyParts = entries.map((e) => e.bodyPart).toSet().toList();
    double minX = start.millisecondsSinceEpoch.toDouble();
    double maxX = end.millisecondsSinceEpoch.toDouble();

    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        minX: minX,
        maxX: maxX,
        minY: -1,
        maxY: 11,
        backgroundColor: Colors.transparent,
        lineBarsData: [
          ...bodyParts.map(
            (bodyPart) => line(
              entries
                  .where((e) => e.bodyPart == bodyPart)
                  .toList()
                  .map(
                    (e) => FlSpot(
                      e.time.millisecondsSinceEpoch.toDouble(),
                      e.painLevel.toDouble(),
                    ),
                  )
                  .toList(),
              AppTheme.colors.bodyPartToColor(bodyPart),
            ),
          )
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            tooltipBgColor: Colors.white,
            getTooltipItems: (List<LineBarSpot> spots) {
              return spots
                  .map((spot) => tooltipForSpot(context, spot))
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  LineTooltipItem tooltipForSpot(BuildContext context, LineBarSpot spot) {
    PainLevelEntry? entryForSpot = entries.firstWhereOrNull((e) =>
        e.time.millisecondsSinceEpoch.toDouble() == spot.x &&
        spot.y == e.painLevel.toDouble());

    return LineTooltipItem(
      '${entryForSpot?.title(context)}\n${displayDateForDay(spot.x)}',
      const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String displayDateForDay(double millis) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(millis.toInt());
    return DateFormat('dd MMM').format(date);
  }

  double dayOffsetFor(DateTime date) {
    return date.difference(start).inDays.toDouble();
  }

  LineChartBarData line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      preventCurveOverShooting: true,
      barWidth: 2,
      isCurved: true,
      curveSmoothness: 0.1,
      color: color,
      dotData: FlDotData(
        show: true,
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}
