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

enum BarChartDisplayMode { energy, activity, sedentary }

class EnergyBarChart extends ConsumerWidget {
  final BarChartDisplayMode displayMode;

  const EnergyBarChart({
    Key? key,
    this.displayMode = BarChartDisplayMode.energy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(energyProvider(ref.watch(paginationProvider))).when(
          data: (values) => _body(
            ref.watch(paginationProvider).mode,
            values,
          ),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
  }

  Widget _body(ChartMode mode, List<Energy> energy) {
    if (energy.isEmpty) {
      return ChartWrapper.empty();
    }

    // get max value from energy
    double maxValue = energy.map(_getValue).reduce(max);
    double width = mode == ChartMode.week ? 32 : 6;

    var groups = {
      ..._emptyMapForMode(energy.last.time, mode),
      ..._groupForMode(energy, mode),
    };

    return ChartWrapper(
      isCard: false,
      child: BarChart(
        BarChartData(
          maxY: mode == ChartMode.day ? 60 : maxValue + (maxValue * 0.1),
          alignment: BarChartAlignment.spaceEvenly,
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (double value, _) {
                  if (value == maxValue + (maxValue * 0.1)) return Container();
                  return Center(
                    child: Text(
                      value.toString(),
                      style: AppTheme.labelTiny,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (double value, _) {
                  return SideTitleWidget(
                    child: Text(
                      _getTitle(value, mode),
                      style: AppTheme.labelTiny,
                    ),
                    axisSide: AxisSide.bottom,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: groups.entries
              .sorted((a, b) => a.key.compareTo(b.key))
              .map((timestamp) => BarChartGroupData(
                    x: timestamp.key.millisecondsSinceEpoch,
                    groupVertically: true,
                    barRods: _groupToBars(
                      timestamp.value.where((e) => _getValue(e) > 0).toList(),
                      width,
                      mode,
                    ),
                  ))
              .toList(),
        ),
        swapAnimationCurve: Curves.easeOut,
      ),
    );
  }

  // DateTime
  Map<DateTime, List<Energy>> _emptyMapForMode(DateTime base, ChartMode mode) {
    switch (mode) {
      case ChartMode.day:
        return {
          for (int i = 0; i < 24; i++)
            DateTime(base.year, base.month, base.day, i): [],
        };
      case ChartMode.week:
        return {
          for (int i = 0; i < 6; i++)
            DateTime(
              base.subtract(Duration(days: i)).year,
              base.subtract(Duration(days: i)).month,
              base.subtract(Duration(days: i)).day,
            ): [],
        };
      case ChartMode.month:
        return {
          for (int i = 0; i < 30; i++)
            DateTime(
              base.subtract(Duration(days: i)).year,
              base.subtract(Duration(days: i)).month,
              base.subtract(Duration(days: i)).day,
            ): [],
        };
      case ChartMode.year:
        return {
          for (int i = 0; i < 11; i++)
            DateTime(
              base.subtract(Duration(days: 31 * i)).year,
              base.subtract(Duration(days: 31 * i)).month,
            ): [],
        };
    }
  }

  Map<DateTime, List<Energy>> _groupForMode(
      List<Energy> energy, ChartMode mode) {
    switch (mode) {
      case ChartMode.day:
        return groupBy(
          energy,
          (Energy e) =>
              DateTime(e.time.year, e.time.month, e.time.day, e.time.hour),
        );
      case ChartMode.week:
      case ChartMode.month:
        return groupBy(
          energy,
          (Energy e) => DateTime(e.time.year, e.time.month, e.time.day),
        );
      case ChartMode.year:
        return groupBy(
          energy,
          (Energy e) => DateTime(e.time.year, e.time.month),
        );
      default:
    }
    return groupBy(energy, (Energy e) => e.time);
  }

  List<BarChartRodData> _groupToBars(
      List<Energy> energy, double width, ChartMode mode) {
    if (energy.isEmpty) {
      return [BarChartRodData(fromY: 0, toY: 0, width: width)];
    }

    if (mode == ChartMode.day) {
      int value = energy.fold<int>(0, (a, b) => a + b.minutes);
      return [
        BarChartRodData(
          fromY: 0,
          toY: value.toDouble(),
          width: width,
          color: _colorForDisplayMode(energy.first),
          borderRadius: _getBorderRadius(0, 1),
        )
      ];
    }

    double startValue = 0;
    List<BarChartRodData> bars = [];
    for (Energy e in energy) {
      int index = energy.indexOf(e);
      double value = _getValue(e);

      bars.add(BarChartRodData(
        fromY: startValue,
        toY: startValue + value,
        width: width,
        color: _colorForDisplayMode(e),
        borderRadius: _getBorderRadius(index, energy.length),
      ));

      startValue += value;
    }
    return bars;
  }

  Color _colorForDisplayMode(Energy e) {
    switch (displayMode) {
      case BarChartDisplayMode.energy:
        return AppTheme.colors.yellow;
      case BarChartDisplayMode.sedentary:
      case BarChartDisplayMode.activity:
        return AppTheme.colors.activityLevelToColor(e.movementLevel);
    }
  }

  double _getValue(Energy e) {
    switch (displayMode) {
      case BarChartDisplayMode.energy:
        return e.value;
      case BarChartDisplayMode.activity:
        return e.minutes.toDouble();
      case BarChartDisplayMode.sedentary:
        if (e.movementLevel != MovementLevel.sedentary) {
          return 0;
        }
        return e.minutes.toDouble();
    }
  }

  BorderRadius _getBorderRadius(int index, int length) {
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

  String _getTitle(double value, ChartMode mode) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(value.toInt());

    switch (mode) {
      case ChartMode.day:
        return time.hour % 7 == 0 ? DateFormat('HH:mm').format(time) : '';
      case ChartMode.week:
        return DateFormat('EEE').format(time);
      case ChartMode.month:
        return time.day % 7 == 0 ? DateFormat('MMMd').format(time) : '';
      case ChartMode.year:
        return DateFormat('MMM').format(time);
      default:
        return time.toIso8601String().substring(0, 10);
    }
  }
}
