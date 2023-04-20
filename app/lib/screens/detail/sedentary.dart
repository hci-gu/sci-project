import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/widgets/activity_arc/activity_arc.dart';
import 'package:scimovement/widgets/charts/bar_chart.dart';
import 'package:scimovement/widgets/charts/chart_wrapper.dart';
import 'package:scimovement/widgets/info_box.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SedentaryScreen extends ConsumerWidget {
  const SedentaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination pagination = ref.watch(paginationProvider);

    return DetailScreen(
      title: AppLocalizations.of(context)!.sedentary,
      header: StatHeader(
        unit: Unit.time,
        provider: averageSedentaryBout(pagination),
      ),
      height: pagination.mode == ChartMode.day ? 150 : 200,
      pageBuilder: (ctx, page) => pagination.mode == ChartMode.day
          ? SedentaryArc(Pagination(mode: pagination.mode, page: page))
          : SedentaryBarChart(Pagination(mode: pagination.mode, page: page)),
      infoBox: InfoBox(
        title:
            '${AppLocalizations.of(context)!.about} ${AppLocalizations.of(context)!.sedentary}',
        text: AppLocalizations.of(context)!.aboutSedentary,
      ),
    );
  }
}

class SedentaryArc extends ConsumerWidget {
  final Pagination pagination;

  const SedentaryArc(this.pagination, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(boutsProvider(pagination)).when(
          data: (data) => ActivityArc(
            bouts: data.where((e) => e.activity == Activity.sedentary).toList(),
            activities: const [Activity.sedentary],
          ),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
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
            unit: Unit.time,
          ),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
  }
}
