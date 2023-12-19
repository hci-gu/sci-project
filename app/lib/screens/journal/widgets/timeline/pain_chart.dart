import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/models/journal/timeline_chart.dart';
import 'package:scimovement/screens/journal/widgets/timeline/utils.dart';

class TimelinePainChart extends ConsumerWidget {
  final TimelinePage page;

  const TimelinePainChart({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(timelineLineChartProvider(page)).when(
          data: (data) => _body(context, data),
          error: (_, __) => Container(),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _body(BuildContext context, List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return SizedBox(height: lineChartHeight);
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
      height: lineChartHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: min(daysOffset, 0) * dayWidth,
            child: SizedBox(
              width: max(dayWidth * numDays, dayWidth * daysInMonth),
              height: lineChartHeight,
              child: TimelineChart(
                start: firstDataDay.isAfter(page.pagination.from)
                    ? page.pagination.from
                    : firstDataDay,
                end: lastDataDay.isBefore(page.pagination.to)
                    ? page.pagination.to
                    : lastDataDay,
                items: entries.map(itemForEntry).toList(),
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
  final List<TimelineChartItem> items;

  const TimelineChart({
    super.key,
    required this.start,
    required this.end,
    this.items = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Category> categories = items.map((e) => e.category).toSet().toList();
    categories.sort((a, b) => b.sort - a.sort);
    double minX = start.millisecondsSinceEpoch.toDouble();
    double maxX = end.millisecondsSinceEpoch.toDouble();

    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        minX: minX,
        maxX: maxX,
        minY: -1,
        maxY: 11,
        backgroundColor: Colors.transparent,
        lineBarsData: categories
            .map(
              (category) => line(
                items
                    .where((e) => e.category.name == category.name)
                    .map((e) => FlSpot(e.x, e.y))
                    .toList(),
                category.color,
                category.isStepLine,
              ),
            )
            .toList(),
        lineTouchData: LineTouchData(
          touchCallback: (FlTouchEvent _, LineTouchResponse? touchResponse) {
            if (touchResponse != null) {
              List<TimelineChartItem> touchedItems = items
                  .where((e) => touchResponse.lineBarSpots != null
                      ? touchResponse.lineBarSpots!.any((spot) => spot.x == e.x)
                      : false)
                  .toList();

              ref.read(timelineTouchedDateProvider.notifier).state =
                  touchedItems.isNotEmpty
                      ? DateTime.fromMillisecondsSinceEpoch(
                          touchedItems.first.x.toInt())
                      : null;
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
    List<TimelineChartItem> itemsForSpot = items
        .where((e) => spots.any((spot) => e.x == spot.x && spot.y == e.y))
        .toList();

    return itemsForSpot.map((e) {
      HSLColor color = HSLColor.fromColor(e.category.color);
      Color textColor =
          color.withLightness(max(0, color.lightness - 0.45)).toColor();
      Color bgColor = color.withLightness(0.9).toColor();
      return LineTooltipItem(
        '',
        const TextStyle(),
        children: [
          TextSpan(
            text: e.y.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              background: Paint()
                ..color = bgColor
                ..strokeWidth = 17
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
      barWidth: isStepLine ? 1 : 2,
      isCurved: false,
      color: color,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      isStepLineChart: isStepLine,
      lineChartStepData: const LineChartStepData(stepDirection: 0),
    );
  }
}
