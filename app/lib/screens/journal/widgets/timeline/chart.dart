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

  String _displayDate(DateTime date) {
    return date.toIso8601String().substring(0, 10);
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
                monthStart: page.pagination.from,
                monthEnd: DateTime(page.pagination.to.year,
                    page.pagination.to.month, 0, 23, 59),
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
  final DateTime monthStart;
  final DateTime monthEnd;
  final List<PainLevelEntry> entries;

  const TimelineChart({
    super.key,
    required this.start,
    required this.end,
    required this.monthStart,
    required this.monthEnd,
    this.entries = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<BodyPart> bodyParts = entries.map((e) => e.bodyPart).toSet().toList();
    double minX = start.millisecondsSinceEpoch.toDouble();
    double maxX = end.millisecondsSinceEpoch.toDouble();

    double monthX = monthStart.millisecondsSinceEpoch.toDouble();
    double monthWidth = monthEnd.millisecondsSinceEpoch.toDouble();

    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: false,
          drawVerticalLine: true,
          drawHorizontalLine: false,
          verticalInterval: const Duration(days: 1).inMilliseconds.toDouble(),
        ),
        titlesData: FlTitlesData(show: false),
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
            ),
          ),
          // line(
          //   entries
          //       .where((e) => e.comment.isNotEmpty)
          //       .map((e) => FlSpot(
          //             e.time.millisecondsSinceEpoch.toDouble(),
          //             e.painLevel.toDouble() + 1,
          //           ))
          //       .toList(),
          //   Colors.black,
          // ),
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
      Color textColor = color.withLightness(color.lightness - 0.45).toColor();
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

  LineChartBarData line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      preventCurveOverShooting: false,
      barWidth: 2,
      isCurved: false,
      curveSmoothness: 0.1,
      color: color,
      dotData: FlDotData(
        show: true,
        // getDotPainter: (spot, x, data, p3) {
        //   return FlDotCirclePainter(
        //     radius: 0,
        //     color: color,
        //     // strokeWidth: 1,
        //     // strokeColor: Colors.black,
        //   );
        // },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}
