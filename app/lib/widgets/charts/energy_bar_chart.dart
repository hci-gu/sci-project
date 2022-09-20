import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/charts/chart_wrapper.dart';

class EnergyBarChart extends ConsumerWidget {
  final bool displayCalories;

  const EnergyBarChart({
    Key? key,
    this.displayCalories = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(energyProvider(ref.watch(paginationProvider))).when(
          data: (values) => _body(ref.watch(paginationProvider).mode, values),
          error: (_, __) => ChartWrapper.empty(),
          loading: () => ChartWrapper.loading(),
        );
  }

  Widget _body(ChartMode mode, List<Energy> energy) {
    if (energy.isEmpty) {
      return ChartWrapper.empty();
    }

    // get max value from energy
    double maxValue = energy
        .map((e) => displayCalories ? e.value : e.minutes?.toDouble() ?? 0)
        .reduce(max);
    double width = mode == ChartMode.week ? 32 : 6;

    Map<DateTime, List<Energy>> groups = groupBy(energy, (Energy e) => e.time);

    return ChartWrapper(
      isCard: false,
      child: BarChart(
        BarChartData(
          maxY: maxValue + 100,
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (double value, _) {
                  return Center(
                    child: Text(
                      getTitle(value, mode),
                      style: AppTheme.labelTiny,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: groups.entries
              .map((timestamp) => BarChartGroupData(
                    x: timestamp.key.millisecondsSinceEpoch,
                    groupVertically: true,
                    barRods: groupToBars(
                      timestamp.value
                          .where((e) => displayCalories
                              ? e.value > 0
                              : (e.minutes != null && e.minutes! > 0))
                          .toList(),
                      width,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  List<BarChartRodData> groupToBars(List<Energy> energy, double width) {
    double startValue = 0;
    List<BarChartRodData> bars = [];
    for (Energy e in energy) {
      int index = energy.indexOf(e);
      double value = displayCalories ? e.value : e.minutes?.toDouble() ?? 0.0;

      bars.add(BarChartRodData(
        fromY: startValue,
        toY: startValue + value,
        width: width,
        color: displayCalories
            ? AppTheme.colors.yellow
            : AppTheme.colors.activityLevelToColor(e.movementLevel),
        borderRadius: getBorderRadius(index, energy.length),
      ));

      startValue += value;
    }
    return bars;
  }

  BorderRadius getBorderRadius(int index, int length) {
    Radius r = const Radius.circular(8);
    if (length == 1) {
      return BorderRadius.all(r);
    }

    return index == 0
        ? BorderRadius.only(bottomLeft: r, bottomRight: r)
        : index == length - 1
            ? BorderRadius.only(topLeft: r, topRight: r)
            : BorderRadius.circular(0);
  }

  String getTitle(double value, ChartMode mode) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(value.toInt());

    switch (mode) {
      case ChartMode.week:
        return DateFormat('EEE').format(time);
      case ChartMode.month:
        return DateFormat('MMMd').format(time);
      case ChartMode.year:
        return DateFormat('MMMM').format(time);
      default:
        return time.toIso8601String().substring(0, 10);
    }
  }
}
