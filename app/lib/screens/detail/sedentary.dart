import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/widgets/charts/bar_chart.dart';
import 'package:scimovement/widgets/charts/chart_wrapper.dart';
import 'package:scimovement/widgets/info_box.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:scimovement/widgets/stat_widget.dart';

class SedentaryScreen extends ConsumerWidget {
  const SedentaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination pagination = ref.watch(paginationProvider);

    return DetailScreen(
      title: 'Stillasittande',
      header: StatHeader(
        unit: Unit.time,
        averageProvider: averageSedentaryBout(pagination),
        totalProvider: totalSedentaryBout(pagination),
      ),
      pageBuilder: (ctx, page) =>
          SedentaryBarChart(Pagination(page: page, mode: pagination.mode)),
      infoBox: const InfoBox(
        title: 'Om Stillasittande',
        text:
            'Här kan du se hur länge du varit stillasittande idag. Det är viktigt att undvika för långa perioder av stillasittande under dagen. Vill du ha hjälp kan se till att ha på notiser för påminnelse att röra på sig.\n\nVill du veta mer om hur stillasittande påverkar dig kan du följa länken nedan.',
      ),
    );
  }
}

class SedentaryBarChart extends ConsumerWidget {
  final Pagination pagination;

  const SedentaryBarChart(this.pagination, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(sedentaryBarChartProvider(pagination)).when(
          data: (values) => CustomBarChart(
            chartData: values,
            displayMode: BarChartDisplayMode.sedentary,
          ),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
  }
}
