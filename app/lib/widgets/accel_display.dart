import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/energy.dart';
import 'dart:math';

class AccelDisplay extends HookWidget {
  final bool showEmpty;

  const AccelDisplay({Key? key, this.showEmpty = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EnergyModel energyModel = Provider.of<EnergyModel>(context);

    if (energyModel.accel.isEmpty) {
      if (showEmpty) {
        return _wrapper(const Center(child: CircularProgressIndicator()));
      }
      return Container();
    }

    return _wrapper(_chart(energyModel.accel));
  }

  Widget _wrapper(Widget child) {
    return AspectRatio(
      aspectRatio: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
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
            left: 4,
            right: 4,
            top: 4,
            bottom: 4,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _chart(List<Accel> accel) {
    List<double> values = accel.map((e) => e.a).toList();
    List<double> displayValues = values;
    double maxValue = displayValues.reduce(max);
    double minValue = displayValues.reduce(min);

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
          show: false,
        ),
        minX: accel.first.time.millisecondsSinceEpoch.toDouble(),
        maxX: accel.last.time.millisecondsSinceEpoch.toDouble(),
        minY: (minValue - maxValue * 0.2).round().toDouble(),
        maxY: (maxValue + maxValue * 0.2).round().toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: accel
                .map(
                  (e) => FlSpot(
                    e.time.millisecondsSinceEpoch.toDouble(),
                    displayValues[accel.indexOf(e)],
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
