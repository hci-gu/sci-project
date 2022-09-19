import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/theme/theme.dart';
import 'dart:math';
import 'package:scimovement/widgets/chart_wrapper.dart';

class ChartValues {
  final List<Energy> previous;
  final List<Energy> current;

  const ChartValues(this.current, this.previous);
}

final energyChartProvider = FutureProvider<ChartValues>((ref) async {
  List<Energy> current =
      await ref.watch(dailyEnergyChartProvider(const Pagination()).future);
  List<Energy> previous = await ref
      .watch(dailyEnergyChartProvider(const Pagination(page: 1)).future);
  return ChartValues(
    current,
    previous
        .map(
          (e) => Energy(
            DateTime(
              e.time.year,
              e.time.month,
              e.time.day + 1,
              e.time.hour,
              e.time.minute,
            ),
            e.value,
          ),
        )
        .toList(),
  );
});

class EnergyDisplay extends ConsumerWidget {
  final bool isCard;

  const EnergyDisplay({
    Key? key,
    this.isCard = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ref.watch(energyChartProvider).when(
              data: (values) => ChartWrapper(
                loading: false,
                isEmpty: false,
                isCard: isCard,
                child: _energyChart(values.current, values.previous),
              ),
              error: (_, __) => ChartWrapper(
                loading: false,
                isEmpty: true,
                isCard: isCard,
                child: Container(),
              ),
              loading: () => ChartWrapper(
                loading: true,
                isEmpty: false,
                isCard: isCard,
                child: Container(),
              ),
            ),
        //   loading: energyModel.loading,
        //   isEmpty: energyModel.energy.isEmpty,
        // ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _energyChart(List<Energy> energy, List<Energy> prevEnergy) {
    if (energy.isEmpty) return Container();

    DateTime energyDate = energy.first.time;
    DateTime day = DateTime(energyDate.year, energyDate.month, energyDate.day);
    List<double> values = energy.map((e) => e.value).toList();
    List<double> prevValues = prevEnergy.map((e) => e.value).toList();
    List<double> allValues = [...values, ...prevValues];
    double maxValue = allValues.isNotEmpty ? allValues.reduce(max) : 0;

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
          rightTitles: SideTitles(showTitles: false),
          topTitles: SideTitles(showTitles: false),
          bottomTitles: SideTitles(
            showTitles: true,
            interval: 60 * 1000 * 60 * 5,
            rotateAngle: -30,
            getTextStyles: (context, value) => const TextStyle(
              color: Color(0xff67727d),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            getTitles: (value) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return date.toString().substring(10, 16);
            },
          ),
          leftTitles: SideTitles(
            margin: 0,
            reservedSize: 20,
            showTitles: true,
            getTextStyles: (context, value) => const TextStyle(
              color: Color(0xff67727d),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        minX: DateTime(day.year, day.month, day.day)
            .millisecondsSinceEpoch
            .toDouble(),
        maxX: DateTime(day.year, day.month, day.day, 23, 59)
            .millisecondsSinceEpoch
            .toDouble(),
        minY: 0,
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
            barWidth: 3,
            isCurved: true,
            colors: [AppTheme.colors.orange],
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, data) => spot.x == data.spots.last.x,
            ),
            belowBarData: BarAreaData(show: false),
          ),
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
            barWidth: 3,
            isCurved: true,
            colors: [AppTheme.colors.lightGray],
            dotData: FlDotData(
              show: false,
            ),
            dashArray: [4, 4],
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
