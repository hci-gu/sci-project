import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/widgets/chart_wrapper.dart';

class HeartRateChart extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final List<HeartRate> heartRates;

  const HeartRateChart({
    Key? key,
    required this.heartRates,
    required this.from,
    required this.to,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChartWrapper(
      child: _chart(),
      loading: false,
      isEmpty: heartRates.isEmpty,
    );
  }

  Widget _chart() {
    if (heartRates.isEmpty) return Container();

    List<double> values = heartRates.map((HeartRate hr) => hr.value).toList();
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
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
        minX: heartRates.first.time.microsecondsSinceEpoch.toDouble(),
        maxX: heartRates.last.time.microsecondsSinceEpoch.toDouble(),
        minY: values.reduce(min) - 10,
        maxY: (values.reduce(max) + 10).roundToDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: heartRates
                .map(
                  (e) => FlSpot(
                    e.time.millisecondsSinceEpoch.toDouble(),
                    e.value,
                  ),
                )
                .toList(),
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(show: false),
          )
        ],
      ),
    );
  }
}
