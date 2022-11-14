import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'dart:math';
import 'package:scimovement/widgets/charts/chart_wrapper.dart';

class ChartValues {
  final List<Energy> previous;
  final List<Energy> current;

  const ChartValues(this.current, this.previous);
}

final energyChartProvider =
    FutureProvider.family<ChartValues, Pagination>((ref, pagination) async {
  List<Energy> current =
      await ref.watch(dailyEnergyChartProvider(pagination).future);
  List<Energy> previous = await ref.watch(
      dailyEnergyChartProvider(Pagination(page: pagination.page + 1)).future);
  return ChartValues(
    current,
    previous
        .map(
          (e) => Energy(
            time: DateTime(
              e.time.year,
              e.time.month,
              e.time.day + 1,
              e.time.hour,
              e.time.minute,
            ),
            value: e.value,
          ),
        )
        .toList(),
  );
});

class EnergyLineChart extends ConsumerWidget {
  final bool isCard;
  final Pagination pagination;

  const EnergyLineChart({
    Key? key,
    this.pagination = const Pagination(),
    this.isCard = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(energyChartProvider(pagination)).when(
          data: (values) => Stack(children: [
            _legend(ref),
            ChartWrapper(
              isCard: isCard,
              child: _energyChart(values.current, values.previous),
              aspectRatio: 1.4,
            )
          ]),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
  }

  TextStyle _styleForText(String text) {
    if (text.length >= 10) {
      return AppTheme.labelTiny;
    }
    return AppTheme.labelMedium;
  }

  Widget _legend(WidgetRef ref) {
    String current = ref.watch(dateDisplayProvider);
    String previous = ref.watch(previousDateDisplayProvider);

    return Positioned(
      top: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            current,
            style:
                _styleForText(current).copyWith(color: AppTheme.colors.orange),
          ),
          Text(
            previous,
            style:
                _styleForText(previous).copyWith(color: AppTheme.colors.gray),
          ),
        ],
      ),
    );
  }

  Widget _energyChart(List<Energy> energy, List<Energy> prevEnergy) {
    if (energy.isEmpty) return Container();

    DateTime energyDate = energy.first.time;
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime day = DateTime(energyDate.year, energyDate.month, energyDate.day);
    List<double> values = energy.map((e) => e.value).toList();
    List<double> prevValues = prevEnergy.map((e) => e.value).toList();
    List<double> allValues = [...values, ...prevValues];

    double maxValue = allValues.isNotEmpty ? allValues.reduce(max) : 0;
    double minX = DateTime(day.year, day.month, day.day)
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
        maxY: (maxValue * 1.25).round().toDouble(),
        backgroundColor: Colors.transparent,
        lineBarsData: [
          LineChartBarData(
            spots: prevEnergy
                .map(
                  (e) => FlSpot(
                    e.time.millisecondsSinceEpoch.toDouble(),
                    prevValues[prevEnergy.indexOf(e)],
                  ),
                )
                .toList(),
            preventCurveOverShooting: true,
            barWidth: 2,
            isCurved: true,
            color: AppTheme.colors.gray,
            dotData: FlDotData(
              show: false,
            ),
            dashArray: [4, 4],
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: energy
                .map(
                  (e) => FlSpot(
                    e.time.millisecondsSinceEpoch.toDouble(),
                    values[energy.indexOf(e)],
                  ),
                )
                .toList(),
            barWidth: 3,
            isCurved: true,
            color: AppTheme.colors.orange,
            dotData: FlDotData(
              show: day == today,
              checkToShowDot: (spot, data) => spot.x == data.spots.last.x,
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
