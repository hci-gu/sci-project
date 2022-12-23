import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/widgets/activity_arc/activity_arc.dart';
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
    bool isDay = pagination.mode == ChartMode.day;

    return DetailScreen(
      title: 'Rörelse',
      header: StatHeader(
        unit: Unit.time,
        isAverage: !isDay,
        provider: isDay
            ? totalMovementMinutesProvider(pagination)
            : averageMovementMinutesProvider(pagination),
      ),
      height: pagination.mode == ChartMode.day ? 175 : 200,
      pageBuilder: (ctx, page) => isDay
          ? AllActivitiesArc(Pagination(mode: pagination.mode, page: page))
          : ActivityBarChart(Pagination(mode: pagination.mode, page: page)),
      infoBox: const InfoBox(
        title: 'Om Rörelse',
        text:
            'Här visas en uppskattning av din dagliga aktivitet. Rörelse (lågintensiv aktivitet, blå). Består av aktiviteter som upplevs som lätt ansträngning och kan beskrivas som 20 - 45% av en individs maximal kapacitet.\nAktivitet (Medel till hög intensiv aktivitet, grön). Består av aktiviteter som upplevs som något ansträngande till ansträngande och mycket ansträngande. Dessa kan beskrivas som medel 46 - 63% och hög 54 - 90% av maximal intensitet.\n\nAktivitetsnivån är baserad på procent (%) av maximal kapacitet (relativ intensitet), detta gör att samma aktivitet kan uppfattas olika anstränga hos olika individer.',
      ),
    );
  }
}

class AllActivitiesArc extends ConsumerWidget {
  final Pagination pagination;

  const AllActivitiesArc(this.pagination, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(boutsProvider(pagination)).when(
          data: (data) => ActivityArc(bouts: data),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
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
            unit: Unit.time,
          ),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
  }
}
