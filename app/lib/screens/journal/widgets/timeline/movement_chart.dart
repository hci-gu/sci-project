import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/journal/widgets/timeline/utils.dart';
import 'package:scimovement/theme/theme.dart';

class TimelineMovementChart extends ConsumerWidget {
  final Pagination page;

  const TimelineMovementChart({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(boutsProvider(page)).when(
          data: (data) => _body(context, data),
          error: (_, __) => Container(),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _body(BuildContext context, List<Bout> bouts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: eventHeight - 16,
        child: MovementBarChart(bouts: bouts, start: page.from, end: page.to),
      ),
    );
  }
}

class MovementBarChart extends ConsumerWidget {
  final List<Bout> bouts;
  final DateTime start;
  final DateTime end;

  const MovementBarChart({
    super.key,
    required this.bouts,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // double minutesInADay = 24 * 60;
    int days = end.difference(start).inDays;
    double width = pageWidth(context);
    double dayWidth = width / days;
    double barWidth = dayWidth * 0.6;
    double spaceWidth = dayWidth * 0.4;

    Map<DateTime, List<Bout>> boutsByDay = {};
    for (int i = 0; i < end.difference(start).inDays; i++) {
      DateTime date = DateTime(start.year, start.month, start.day + i);
      List<Bout> filtered = bouts
          .where((e) =>
              e.time.isAfter(date) &&
              e.time.isBefore(date.add(const Duration(days: 1))))
          // .where((e) => e.activity != Activity.sedentary)
          .toList();
      boutsByDay[date] = filtered;
    }

    List<int> values = boutsByDay.entries
        .map((e) => e.value.fold(0, (int p, c) => p + c.minutes))
        .toList();
    int maxDay = values.fold(0, (p, c) => math.max(p, c));

    return BarChart(
      BarChartData(
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.colors.lightGray,
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: maxDay.toDouble(),
        minY: 0,
        groupsSpace: spaceWidth,
        barGroups: boutsByDay.entries
            .map(
              (e) => BarChartGroupData(
                x: e.key.millisecondsSinceEpoch,
                groupVertically: true,
                barRods: _boutsToBars(e.value, barWidth),
              ),
            )
            .toList(),
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent _, BarTouchResponse? touchResponse) {
            if (touchResponse != null) {
              int? x = touchResponse.spot?.touchedBarGroup.x;
              DateTime? date =
                  x != null ? DateTime.fromMillisecondsSinceEpoch(x) : null;

              ref.read(timelineTouchedDateProvider.notifier).state = date;
            }
          },
          touchTooltipData: BarTouchTooltipData(
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            tooltipBgColor: Colors.transparent,
            tooltipPadding: const EdgeInsets.all(0),
            // tooltipBottomMargin: 0,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '',
                AppTheme.paragraphSmall.copyWith(
                  color: AppTheme.colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  _boutsToBars(List<Bout> bouts, double width) {
    if (bouts.isEmpty) {
      return [
        BarChartRodData(
          fromY: 0,
          toY: 0,
          width: width,
          color: AppTheme.colors.gray.withOpacity(0.25),
        )
      ];
    }

    List<BarChartRodData> bars = [];

    double startValue = 0;
    bouts.sort((a, b) => a.activity.index.compareTo(b.activity.index));
    for (Bout bout in bouts) {
      int index = bouts.indexOf(bout);

      bars.add(
        BarChartRodData(
          fromY: startValue,
          toY: startValue + bout.minutes.toDouble(),
          width: width,
          color: AppTheme.colors.activityLevelToColor(bout.activity),
          borderRadius: _getBorderRadius(index, bouts.length),
        ),
      );
      startValue += bout.minutes;
    }

    return bars;
  }

  BorderRadius _getBorderRadius(int index, int length) {
    Radius r = const Radius.circular(3);
    if (length == 1) {
      return BorderRadius.all(r);
    }

    return index == 0
        ? BorderRadius.only()
        : index == length - 1
            ? BorderRadius.only(topLeft: r, topRight: r)
            : BorderRadius.circular(0);
  }
}
