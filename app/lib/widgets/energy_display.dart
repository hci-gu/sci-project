import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/energy.dart';
import 'dart:math';

import 'package:scimovement/models/settings.dart';
import 'package:scimovement/theme/theme.dart';

class EnergyDisplay extends HookWidget {
  const EnergyDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EnergyModel energyModel = Provider.of<EnergyModel>(context);
    SettingsModel settings = Provider.of<SettingsModel>(context);

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
        _wrapper(
          energyModel.energy.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _energyChart(energyModel.energy, settings),
        ),
        const SizedBox(height: 8),
        const EnergyChartSettings(),
      ],
    );
  }

  Widget _wrapper(Widget child) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        height: 300,
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
          child: child,
        ),
      ),
    );
  }

  Widget _energyChart(List<Energy> energy, SettingsModel settings) {
    List<double> values = energy.map((e) => e.value).toList();
    List<double> displayValues = values;
    if (settings.energyChartMode == EnergyChartMode.accumulative) {
      for (int i = 1; i < values.length; i++) {
        displayValues[i] = displayValues[i - 1] + values[i];
      }
    }
    double maxValue = displayValues.reduce(max);

    return LineChart(
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
            interval: 60 * 1000 * 200,
            getTextStyles: (context, value) => const TextStyle(
              color: Color(0xff68737d),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            getTitles: (value) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        const Text('Chart: '),
        const SizedBox(width: 8),
        DropdownButton(
          isDense: true,
          items: chartModeItems,
          value: settings.energyChartMode,
          onChanged: (EnergyChartMode? mode) {
            if (mode != null) {
              settings.setEnergyChartMode(mode);
            }
          },
        ),
      ]),
    );
  }
}
