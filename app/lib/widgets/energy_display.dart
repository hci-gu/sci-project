import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/energy.dart';
import 'dart:math';
import 'package:scimovement/widgets/chart_wrapper.dart';

class EnergyDisplay extends HookWidget {
  final bool isCard;

  const EnergyDisplay({
    Key? key,
    this.isCard = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EnergyModel energyModel = Provider.of<EnergyModel>(context);

    return Column(
      children: [
        ChartWrapper(
          isCard: isCard,
          child: _energyChart(
            energyModel.averageEnergy,
            energyModel.prevAverage
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
          ),
          loading: energyModel.loading,
          isEmpty: energyModel.energy.isEmpty,
        ),
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
            preventCurveOverShooting: false,
            barWidth: 3,
            isCurved: true,
            colors: [
              Color.fromARGB(255, 205, 12, 86),
            ],
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
            preventCurveOverShooting: false,
            barWidth: 3,
            isCurved: true,
            colors: const [
              Color.fromRGBO(0, 0, 0, 0.1),
            ],
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
