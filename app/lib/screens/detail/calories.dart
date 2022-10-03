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
    bool isDay = pagination.mode == ChartMode.day;

    return DetailScreen(
      title: 'Kalorier',
      header: StatHeader(
        unit: Unit.calories,
        isAverage: !isDay,
        provider: isDay
            ? totalEnergyProvider(pagination)
            : averageEnergyProvider(pagination),
      ),
      pageBuilder: (ctx, page) => isDay
          ? EnergyLineChart(
              isCard: false,
              pagination: Pagination(page: page, mode: pagination.mode),
            )
          : EnergyBarChart(Pagination(page: page, mode: pagination.mode)),
      infoBox: const InfoBox(
        title: 'Om Kalorier',
        text:
            'Här visas en uppskattningen av din dagliga energiförbrukning (kalorier) vilket sker genom att aktivitetsarmbandet (klockan) registrerar rörelsen från accelerometern och hjärtfrekvensen kontinuerligt. Informationen från aktivitetsarmbandet samt information om skadenivå, kön och kroppsvikt används för att beräkna energiförbrukning samt aktivitetsnivå (intensitet). ',
      ),
    );
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
