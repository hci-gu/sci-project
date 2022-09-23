import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/charts/chart_wrapper.dart';
import 'package:scimovement/widgets/charts/utils/chart_data.dart';

enum BarChartDisplayMode { energy, activity, sedentary }

class CustomBarChart extends StatelessWidget {
  final ChartData chartData;
  final BarChartDisplayMode displayMode;

  const CustomBarChart({
    required this.chartData,
    required this.displayMode,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (chartData.data.isEmpty) {
      return ChartWrapper.empty();
    }
    // get max value from energy
    double width = chartData.mode == ChartMode.week ? 32 : 6;

    return ChartWrapper(
      isCard: false,
      child: BarChart(
        BarChartData(
          maxY: chartData.maxValue,
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
                  if (value == chartData.maxValue) return Container();
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
                      _getTitle(value, chartData.mode),
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
          barGroups: chartData.group.entries
              .sorted((a, b) => a.key.compareTo(b.key))
              .map((timestamp) => BarChartGroupData(
                    x: timestamp.key.millisecondsSinceEpoch,
                    groupVertically: true,
                    barRods: _groupToBars(
                      timestamp.value.where((e) => e.value > 0).toList(),
                      width,
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
          color: _colorForDisplayMode(data.first.activity),
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
        color: _colorForDisplayMode(e.activity),
        borderRadius: _getBorderRadius(index, data.length),
      ));

      startValue += e.value;
    }
    return bars;
  }

  Color _colorForDisplayMode(Activity activity) {
    switch (displayMode) {
      case BarChartDisplayMode.energy:
        return AppTheme.colors.yellow;
      case BarChartDisplayMode.sedentary:
      case BarChartDisplayMode.activity:
        return AppTheme.colors.activityLevelToColor(activity);
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
