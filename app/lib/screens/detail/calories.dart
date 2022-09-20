import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/charts/energy_bar_chart.dart';
import 'package:scimovement/widgets/charts/energy_line_chart.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:scimovement/widgets/stat_widget.dart';

class CaloriesScreen extends ConsumerWidget {
  const CaloriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination page = ref.watch(paginationProvider);

    return DetailScreen(
      title: 'Kalorier',
      header: StatHeader(
        unit: Unit.calories,
        averageProvider: averageEnergyProvider(page),
        totalProvider: totalEnergyProvider(page),
      ),
      body: Column(
        children: [
          AppTheme.separator,
          _isDay(ref)
              ? const EnergyLineChart(isCard: false)
              : const EnergyBarChart(displayMode: BarChartDisplayMode.energy),
          AppTheme.separator,
        ],
      ),
    );
  }

  bool _isDay(WidgetRef ref) {
    return ref.watch(paginationProvider).mode == ChartMode.day;
  }
}
