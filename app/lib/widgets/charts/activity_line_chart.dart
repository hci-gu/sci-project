import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/charts/chart_wrapper.dart';
import 'package:scimovement/widgets/charts/utils/chart_data.dart';

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
    return ref.watch(activityLineChartProvider(pagination)).when(
          data: (values) => ChartWrapper(
            isCard: isCard,
            child: _energyChart(values),
          ),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
  }

  Widget _energyChart(ChartData chartData) {
    if (chartData.data.isEmpty) return Container();

    List<double> values = chartData.data.map((e) => e.value).toList();

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
                if (value == chartData.minX || value == chartData.maxX) {
                  return const SizedBox();
                }
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
        minX: chartData.minX,
        maxX: chartData.maxX,
        minY: -0.1,
        maxY: 2,
        backgroundColor: Colors.transparent,
        lineBarsData: [
          LineChartBarData(
            spots: chartData.data
                .map(
                  (e) => FlSpot(
                    e.time.millisecondsSinceEpoch.toDouble(),
                    values[chartData.data.indexOf(e)],
                  ),
                )
                .toList(),
            barWidth: 3,
            color: AppTheme.colors.sedentary,
            gradient: LinearGradient(
              colors: chartData.maxValue == 2
                  ? [
                      AppTheme.colors.sedentary,
                      AppTheme.colors.moving,
                      AppTheme.colors.active,
                    ]
                  : [
                      AppTheme.colors.sedentary,
                      AppTheme.colors.moving,
                    ],
              stops: chartData.maxValue == 2 ? [0, 1, 2] : [0, 1],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(show: false),
            isStepLineChart: true,
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
