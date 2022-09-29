import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/widgets/activity_arc/activity_arc.dart';
import 'package:scimovement/widgets/charts/activity_line_chart.dart';
import 'package:scimovement/widgets/charts/bar_chart.dart';
import 'package:scimovement/widgets/charts/chart_wrapper.dart';
import 'package:scimovement/widgets/info_box.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:scimovement/widgets/stat_widget.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination pagination = ref.watch(paginationProvider);

    return DetailScreen(
      title: 'Rörelse',
      header: StatHeader(
        unit: Unit.time,
        averageProvider: averageMovementMinutesProvider(pagination),
        totalProvider: totalMovementMinutesProvider(pagination),
      ),
      height: pagination.mode == ChartMode.day ? 150 : 200,
      pageBuilder: (ctx, page) => _isDay(ref)
          ? ref.watch(boutsProvider(pagination)).when(
                data: (data) => ActivityArc(bouts: data),
                error: (_, __) => Container(),
                loading: () => Container(),
              )
          : ActivityBarChart(Pagination(page: page, mode: pagination.mode)),
      infoBox: const InfoBox(
        title: 'Om Rörelse',
        text:
            'Här kan du se din rörelse över dagen. Utan att ange någon information kan vi kategorisera din rörelse i tre olika nivåer när du har på dig klockan. \n\nTotalen längst upp representerar antalet minuter du rört dig idag.',
      ),
    );
  }

  bool _isDay(WidgetRef ref) {
    return ref.watch(paginationProvider).mode == ChartMode.day;
  }
}

class ActivityBarChart extends ConsumerWidget {
  final Pagination pagination;

  const ActivityBarChart(this.pagination, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(activityBarChartProvider(pagination)).when(
          data: (values) => CustomBarChart(
            chartData: values,
            displayMode: BarChartDisplayMode.activity,
          ),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
  }
}
