import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/theme/theme.dart';

class EnergyBarChart extends ConsumerWidget {
  const EnergyBarChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(
          energyProvider(
            Pagination(page: 0, mode: ref.watch(chartModeProvider)),
          ),
        )
        .when(
          data: (values) => _body(ref.watch(chartModeProvider), values),
          error: (_, __) => const Text('error'),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
  }

  Widget _empty() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Text(
          'No data',
          style: AppTheme.paragraphMedium,
        ),
      ),
    );
  }

  Widget _body(ChartMode mode, List<Energy> energy) {
    if (energy.isEmpty) {
      return _empty();
    }

    // get max value from energy
    double maxValue = energy.map((e) => e.value).reduce(max);
    double width = mode == ChartMode.week ? 32 : 6;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: maxValue + 100,
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            show: true,
            topTitles: SideTitles(showTitles: false),
            bottomTitles: SideTitles(
              showTitles: true,
              margin: 20,
              getTextStyles: (BuildContext context, double value) {
                if (energy.last.time.millisecondsSinceEpoch.toDouble() ==
                    value) {
                  return AppTheme.labelTiny.copyWith(
                    fontWeight: FontWeight.w900,
                  );
                }
                return AppTheme.labelTiny;
              },
              interval: mode == ChartMode.week ? 1 : 7,
              getTitles: (double value) {
                DateTime time =
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());

                switch (mode) {
                  case ChartMode.week:
                    return DateFormat('EEE').format(time);
                  case ChartMode.month:
                    return DateFormat('MMMd').format(time);
                  case ChartMode.year:
                    return DateFormat('MMMM').format(time);
                  default:
                    return time.toIso8601String().substring(0, 10);
                }
              },
            ),
            leftTitles: SideTitles(showTitles: false),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          gridData: FlGridData(
            show: false,
          ),
          barGroups: energy
              .map(
                (e) => BarChartGroupData(
                  x: e.time.millisecondsSinceEpoch,
                  barsSpace: width,
                  barRods: [
                    BarChartRodData(
                      y: e.value,
                      width: width,
                      borderRadius: BorderRadius.circular(8),
                      colors: [AppTheme.colors.yellow],
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
