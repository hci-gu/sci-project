import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/widgets/charts/bar_chart.dart';
import 'package:scimovement/widgets/charts/chart_wrapper.dart';
import 'package:scimovement/widgets/charts/energy_line_chart.dart';
import 'package:scimovement/widgets/info_box.dart';
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
          : EnergyBarChart(Pagination(page: page, mode: pagination.mode)),
      infoBox: const InfoBox(
        title: 'Om Kalorier',
        text:
            'Kalorierna som visas här är det totala du har bränt idag. Detta är baserat på din aktivitetsnivå tillsammans med din puls. För att läsa mer om hur vi räknar ut kalorier följ länken nedan.',
      ),
    );
  }

  bool _isDay(WidgetRef ref) {
    return ref.watch(paginationProvider).mode == ChartMode.day;
  }
}

class EnergyBarChart extends ConsumerWidget {
  final Pagination pagination;

  const EnergyBarChart(this.pagination, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(energyBarChartProvider(pagination)).when(
          data: (values) => CustomBarChart(
            chartData: values,
            displayMode: BarChartDisplayMode.energy,
          ),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
  }
}
