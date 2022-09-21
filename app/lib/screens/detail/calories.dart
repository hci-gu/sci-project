import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/widgets/charts/energy_bar_chart.dart';
import 'package:scimovement/widgets/charts/energy_line_chart.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:scimovement/widgets/stat_widget.dart';

class CaloriesScreen extends ConsumerWidget {
  const CaloriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination pagination = ref.watch(paginationProvider);

    return DetailScreen(
      title: 'Kalorier',
      header: StatHeader(
        unit: Unit.calories,
        averageProvider: averageEnergyProvider(pagination),
        totalProvider: totalEnergyProvider(pagination),
      ),
      pageBuilder: (ctx, page) => _isDay(ref)
          ? EnergyLineChart(
              isCard: false,
              pagination: Pagination(page: page, mode: pagination.mode),
            )
          : EnergyBarChart(
              displayMode: BarChartDisplayMode.energy,
              pagination: Pagination(page: page, mode: pagination.mode),
            ),
    );
  }

  bool _isDay(WidgetRef ref) {
    return ref.watch(paginationProvider).mode == ChartMode.day;
  }
}
