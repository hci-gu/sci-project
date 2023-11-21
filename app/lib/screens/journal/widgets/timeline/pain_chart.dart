import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/screens/journal/widgets/timeline/utils.dart';
import 'package:scimovement/theme/theme.dart';

class TimelinePainChart extends ConsumerWidget {
  final TimelinePage page;

  const TimelinePainChart({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(timelinePainChartProvider(page)).when(
          data: (data) => _body(context, data),
          error: (_, __) => Container(),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _body(BuildContext context, List<PainLevelEntry> entries) {
    if (entries.isEmpty) {
      return SizedBox(height: chartEventHeight);
    }
    entries.sort((a, b) => a.time.compareTo(b.time));

    DateTime firstDataDay = DateTime(
      entries.first.time.year,
      entries.first.time.month,
      entries.first.time.day,
    );
    DateTime lastDataDay = DateTime(
      entries.last.time.year,
      entries.last.time.month,
      entries.last.time.day,
    );

    DateTime firstDate = firstDataDay.isAfter(page.pagination.from)
        ? page.pagination.from
        : firstDataDay;
    DateTime lastDate = lastDataDay.isBefore(page.pagination.to)
        ? page.pagination.to
        : lastDataDay;

    int numDays = lastDate.difference(firstDate).inDays;
    int daysInMonth = page.pagination.duration.inDays;
    double width = pageWidth(context);
    double dayWidth = width / daysInMonth;

    int daysOffset = firstDataDay.difference(page.pagination.from).inDays;

    return Container(
      height: chartEventHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Stack(
        // clipBehavior: Clip.none,
        children: [
          Positioned(
            left: daysOffset * dayWidth,
            child: SizedBox(
              width: max(dayWidth * numDays, dayWidth * daysInMonth),
              height: chartEventHeight,
              child: TimelineChart(
                start: firstDataDay.isAfter(page.pagination.from)
                    ? page.pagination.from
                    : firstDataDay,
                end: lastDataDay.isBefore(page.pagination.to)
                    ? page.pagination.to
                    : lastDataDay,
                entries: entries,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class TimelineChart extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    List<BodyPart> bodyParts = entries.map((e) => e.bodyPart).toSet().toList();
    double minX = start.millisecondsSinceEpoch.toDouble();
    double maxX = end.millisecondsSinceEpoch.toDouble();

    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        // rangeAnnotations: RangeAnnotations(
        //   verticalRangeAnnotations: [
        //     VerticalRangeAnnotation(
        //       x1: monthX,
        //       x2: monthWidth,
        //       color: Colors.red.withOpacity(0.5),
        //     ),
        //   ],
        // ),
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
              bodyPart.type == BodyPartType.neuropathic,
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchCallback: (FlTouchEvent _, LineTouchResponse? touchResponse) {
            if (touchResponse != null) {
              List<PainLevelEntry> touchedEntries = entries
                  .where((e) => touchResponse.lineBarSpots != null
                      ? touchResponse.lineBarSpots!.any(
                          (spot) => spot.x == e.time.millisecondsSinceEpoch)
                      : false)
                  .toList();

              ref.read(timelineTouchedDateProvider.notifier).state =
                  touchedEntries.isNotEmpty ? touchedEntries.first.time : null;
            }
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            tooltipBgColor: Colors.transparent,
            getTooltipItems: (List<LineBarSpot> spots) =>
                tooltipsForSpots(context, spots),
          ),
        ),
      ),
    );
  }

  List<LineTooltipItem> tooltipsForSpots(
      BuildContext context, List<LineBarSpot> spots) {
    List<PainLevelEntry> entriesForSpot = entries
        .where((e) => spots.any((spot) =>
            e.time.millisecondsSinceEpoch.toDouble() == spot.x &&
            spot.y == e.painLevel.toDouble()))
        .toList();

    return entriesForSpot.map((e) {
      HSLColor color =
          HSLColor.fromColor(AppTheme.colors.bodyPartToColor(e.bodyPart));
      Color textColor =
          color.withLightness(max(0, color.lightness - 0.45)).toColor();
      Color bgColor = color.withLightness(0.9).toColor();
      return LineTooltipItem(
        '',
        const TextStyle(),
        children: [
          TextSpan(
            text: e.painLevel.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              background: Paint()
                ..color = bgColor
                ..strokeWidth = 10
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke,
            ),
          ),
        ],
      );
    }).toList();
  }

  String displayDateForDay(double millis) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(millis.toInt());
    return DateFormat('dd MMM').format(date);
  }

  double dayOffsetFor(DateTime date) {
    return date.difference(start).inDays.toDouble();
  }

  LineChartBarData line(List<FlSpot> spots, Color color,
      [bool isStepLine = false]) {
    return LineChartBarData(
      spots: spots,
      preventCurveOverShooting: false,
      barWidth: 2,
      isCurved: false,
      color: color,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      isStepLineChart: isStepLine,
      lineChartStepData: const LineChartStepData(stepDirection: 0),
    );
  }
}
