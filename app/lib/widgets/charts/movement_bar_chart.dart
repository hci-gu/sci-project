import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/charts/utils/chart_data.dart';

class MovementBarChart extends StatelessWidget {
  final ChartData chartData;

  const MovementBarChart({
    required this.chartData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (chartData.data.isEmpty) {
      return Container();
    }
    // get max value from energy
    List<MapEntry<DateTime, List<ChartDataPoint>>> groups =
        chartData.group.entries.sorted((a, b) => a.key.compareTo(b.key));

    return SizedBox(
      width: max(chartData.days, 32) * 16.0,
      child: BarChart(
        BarChartData(
          maxY: chartData.maxY,
          titlesData: FlTitlesData(
            show: false,
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: groups
              .map((timestamp) => BarChartGroupData(
                    x: timestamp.key.millisecondsSinceEpoch,
                    groupVertically: true,
                    barRods: _groupToBars(
                      timestamp.value.where((e) => e.value > 0).toList(),
                      6,
                      chartData.mode,
                    ),
                  ))
              .toList(),
        ),
        swapAnimationCurve: Curves.easeOut,
      ),
    );
  }

  List<BarChartRodData> _groupToBars(
      List<ChartDataPoint> data, double width, ChartMode mode) {
    if (data.isEmpty) {
      return [BarChartRodData(fromY: 0, toY: 0, width: width)];
    }

    if (mode == ChartMode.day) {
      double value = data.fold(0, (a, b) => a + b.value);
      return [
        BarChartRodData(
          fromY: 0,
          toY: value,
          width: width,
          color: AppTheme.colors.gray.withOpacity(0.25),
          borderRadius: _getBorderRadius(0, 1),
        )
      ];
    }

    double startValue = 0;
    List<BarChartRodData> bars = [];
    data.sort((a, b) => a.activity.index.compareTo(b.activity.index));
    for (ChartDataPoint e in data) {
      int index = data.indexOf(e);

      bars.add(BarChartRodData(
        fromY: startValue,
        toY: startValue + e.value,
        width: width,
        color: AppTheme.colors.lightGray,
        borderRadius: _getBorderRadius(index, data.length),
      ));

      startValue += e.value;
    }
    return bars;
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
}
