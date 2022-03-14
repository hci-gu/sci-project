import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/models/energy.dart';
import 'dart:math';

import 'package:scimovement/models/settings.dart';
import 'package:scimovement/theme/theme.dart';

class EnergyDisplay extends HookWidget {
  const EnergyDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EnergyModel energyModel = Provider.of<EnergyModel>(context);
    ActivityModel activityModel = Provider.of<ActivityModel>(context);
    SettingsModel settings = Provider.of<SettingsModel>(context);

    useEffect(() {
      energyModel.setFrom(activityModel.earliestDataDate!);
      energyModel.getEnergy(activityModel.from, activityModel.to);
      return () => {};
    }, [activityModel.from]);

    return Column(
      children: [
        Text(
          'Energy',
          style: AppTheme.titleTextStyle,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              energyModel.total.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 2, top: 6.0),
              child: Text(
                'kcal',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (energyModel.energy.isNotEmpty)
          _energyChart(energyModel.energy, settings),
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
        EnergyChartSettings(),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Text(
        //         'from: ${energyModel.from.toIso8601String().substring(11, 19)}'),
        //     Text('to: ${energyModel.to.toIso8601String().substring(11, 19)}'),
        //   ],
        // ),
      ],
    );
  }

  Widget _energyChart(List<Energy> energy, SettingsModel settings) {
    List<double> values = energy.map((e) => e.value).toList();
    List<double> displayValues = values;
    if (settings.energyChartMode == EnergyChartMode.accumulative) {
      for (int i = 1; i < values.length; i++) {
        displayValues[i] = displayValues[i - 1] + values[i];
      }
    } else if (settings.energyChartMode == EnergyChartMode.fiveMin) {
      // sum up every 5 minutes and display
      displayValues = List<double>.filled(
        values.length ~/ 5,
        0,
      );
    }
    double maxValue = displayValues.reduce(max);

    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.only(
            left: 12,
            right: 24,
            top: 16,
            bottom: 4,
          ),
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
                    fontSize: 12,
                  ),
                ),
              ),
              minX: settings.minTimeForChart(energy.first.time),
              maxX: settings.maxTimeForChart(energy.last.time),
              minY: 0,
              maxY: (maxValue + maxValue * 0.2).round().toDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: energy
                      .map(
                        (e) => FlSpot(
                          e.time.millisecondsSinceEpoch.toDouble(),
                          displayValues[energy.indexOf(e)],
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

class EnergyChartSettings extends StatelessWidget {
  const EnergyChartSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SettingsModel settings = Provider.of<SettingsModel>(context);

    final List<DropdownMenuItem<EnergyChartMode>> chartModeItems =
        EnergyChartMode.values.map((EnergyChartMode mode) {
      return DropdownMenuItem<EnergyChartMode>(
        value: mode,
        child: Text(
          mode.name,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      );
    }).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DropdownButton(
          isDense: true,
          items: chartModeItems,
          value: settings.energyChartMode,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          onChanged: (EnergyChartMode? mode) {
            if (mode != null) {
              settings.setEnergyChartMode(mode);
            }
          },
        ),
      ),
    );
  }
}
