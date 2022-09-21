import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/theme/theme.dart';
import 'dart:math';
import 'package:scimovement/widgets/charts/chart_wrapper.dart';

class ActivityLineChart extends ConsumerWidget {
  final bool isCard;
  final Pagination pagination;

  const ActivityLineChart({
    Key? key,
    this.pagination = const Pagination(),
    this.isCard = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(energyProvider(pagination)).when(
          data: (values) => ChartWrapper(
            isCard: isCard,
            child: _energyChart(values),
          ),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
  }

  double _valueForMovementLevel(Energy e) {
    switch (e.movementLevel) {
      case MovementLevel.sedentary:
        return 0;
      case MovementLevel.moving:
        return 1;
      case MovementLevel.active:
        return 2;
    }
  }

  Widget _energyChart(List<Energy> energy) {
    if (energy.isEmpty) return Container();

    DateTime energyDate = energy.first.time;
    DateTime day = DateTime(energyDate.year, energyDate.month, energyDate.day);
    List<double> values = energy.map(_valueForMovementLevel).toList();

    double maxValue = values.isNotEmpty ? values.reduce(max) : 0;
    double minX = DateTime(day.year, day.month, day.day, 5)
        .millisecondsSinceEpoch
        .toDouble();
    double maxX = DateTime(day.year, day.month, day.day, 23, 59)
        .millisecondsSinceEpoch
        .toDouble();

    return LineChart(
      LineChartData(
        borderData: FlBorderData(
          show: false,
        ),
        gridData: FlGridData(
          show: false,
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 60 * 1000 * 60 * 5,
              reservedSize: 24,
              getTitlesWidget: (value, _) {
                if (value == minX || value == maxX) return const SizedBox();
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Center(
                  child: Text(
                    DateFormat('HH:mm').format(date),
                    style: AppTheme.labelTiny,
                  ),
                );
              },
            ),
          ),
        ),
        minX: minX,
        maxX: maxX,
        minY: -0.1,
        maxY: (maxValue + maxValue * 0.2).round().toDouble(),
        backgroundColor: Colors.transparent,
        lineBarsData: [
          LineChartBarData(
            spots: energy
                .map(
                  (e) => FlSpot(
                    e.time.millisecondsSinceEpoch.toDouble(),
                    values[energy.indexOf(e)],
                  ),
                )
                .toList(),
            barWidth: 2,
            color: AppTheme.colors.sedentary,
            gradient: LinearGradient(
              colors: [
                AppTheme.colors.sedentary,
                AppTheme.colors.moving,
                AppTheme.colors.active,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            getTooltipItems: (List<LineBarSpot> spots) {
              return spots
                  .map(
                    (spot) => LineTooltipItem(
                      'kcal: ${spot.y.toStringAsFixed(1)}\n${DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()).toString().substring(10, 16)}',
                      const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ),
      ),
      swapAnimationCurve: Curves.easeInOut,
      swapAnimationDuration: const Duration(milliseconds: 800),
    );
  }
}
