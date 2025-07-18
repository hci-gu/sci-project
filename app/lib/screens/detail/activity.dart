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
import 'package:scimovement/gen_l10n/app_localizations.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination pagination = ref.watch(paginationProvider);
    bool isDay = pagination.mode == ChartMode.day;

    return DetailScreen(
      title: AppLocalizations.of(context)!.movement,
      header: StatHeader(
        unit: Unit.time,
        isAverage: !isDay,
        provider: isDay
            ? totalMovementMinutesProvider(pagination)
            : averageMovementMinutesProvider(pagination),
      ),
      height: pagination.mode == ChartMode.day ? 180 : 200,
      pageBuilder: (ctx, page) => isDay
          ? AllActivitiesArc(Pagination(mode: pagination.mode, page: page))
          : ActivityBarChart(Pagination(mode: pagination.mode, page: page)),
      content: Column(
        children: [
          InfoBox(
            title:
                '${AppLocalizations.of(context)!.about} ${AppLocalizations.of(context)!.movement}',
            text: AppLocalizations.of(context)!.aboutMovement,
          ),
        ],
      ),
    );
  }
}

class AllActivitiesArc extends ConsumerWidget {
  final Pagination pagination;

  const AllActivitiesArc(this.pagination, {super.key});

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

  const ActivityBarChart(this.pagination, {super.key});

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
