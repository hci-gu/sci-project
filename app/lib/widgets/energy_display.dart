import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/models/energy.dart';
import 'dart:math';

class EnergyDisplay extends HookWidget {
  const EnergyDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EnergyModel energyModel = Provider.of<EnergyModel>(context);
    ActivityModel activityModel = Provider.of<ActivityModel>(context);

    useEffect(() {
      energyModel.setFrom(activityModel.earliestDataDate!);
      energyModel.getEnergy(activityModel.from, activityModel.to);
      return () => {};
    }, [activityModel.from]);

    return Column(
      children: [
        Text(
          'Energy',
          style: Theme.of(context).textTheme.headline6,
        ),
        const SizedBox(height: 8),
        Text(
          '${energyModel.total.toStringAsFixed(1)} kcal',
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        if (energyModel.energy.isNotEmpty) _energyChart(energyModel.energy),
        const SizedBox(height: 8),
        TextButton(
          style: ButtonStyle(
            minimumSize: MaterialStateProperty.all(const Size(100, 40)),
            backgroundColor: MaterialStateProperty.all(Colors.blueGrey),
          ),
          onPressed: () {
            if (!energyModel.loading) {
              energyModel.calculateEnergy(activityModel.lastDataDate!);
            }
          },
          child: energyModel.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Calculate energy',
                  style: TextStyle(color: Colors.white),
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                'from: ${energyModel.from.toIso8601String().substring(11, 19)}'),
            Text('to: ${energyModel.to.toIso8601String().substring(11, 19)}'),
          ],
        ),
      ],
    );
  }

  Widget _energyChart(List<Energy> energy) {
    List<double> values = energy.map((e) => e.value).toList();
    // accumulative values
    List<double> accumulatedValues = values;
    for (int i = 1; i < values.length; i++) {
      accumulatedValues[i] = accumulatedValues[i - 1] + values[i];
    }
    double maxValue = accumulatedValues.reduce(max);

    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xff232d37),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 30,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                // horizontalInterval: 1,
                // verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: const Color(0xff37434d),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: const Color(0xff37434d),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: SideTitles(showTitles: false),
                topTitles: SideTitles(showTitles: false),
                bottomTitles: SideTitles(
                  showTitles: true,
                  interval: 60 * 1000 * 300,
                  getTextStyles: (context, value) => const TextStyle(
                    color: Color(0xff68737d),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  getTitles: (value) {
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return date.toString().substring(10, 16);
                  },
                ),
                leftTitles: SideTitles(
                  reservedSize: 30,
                  showTitles: true,
                  getTextStyles: (context, value) => const TextStyle(
                    color: Color(0xff67727d),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              minX: energy.first.time.millisecondsSinceEpoch.toDouble(),
              maxX: energy.last.time.millisecondsSinceEpoch.toDouble(),
              minY: 0,
              maxY: maxValue + maxValue * 0.2,
              lineBarsData: [
                LineChartBarData(
                  // isCurved: true,
                  // preventCurveOverShooting: true,
                  // curveSmoothness: 2,
                  spots: energy
                      .map(
                        (e) => FlSpot(
                          e.time.millisecondsSinceEpoch.toDouble(),
                          accumulatedValues[energy.indexOf(e)],
                        ),
                      )
                      .toList(),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: false,
                  ),
                  belowBarData: BarAreaData(show: true),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
