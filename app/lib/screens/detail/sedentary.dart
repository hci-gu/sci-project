import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/journal.dart';
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
      content: Column(
        children: [
          InfoBox(
            title:
                '${AppLocalizations.of(context)!.about} ${AppLocalizations.of(context)!.sedentary}',
            text: AppLocalizations.of(context)!.aboutSedentary,
          ),
        ],
      ),
    );
  }
}

class SedentaryArcData {
  final List<Bout> bouts;
  final List<PressureReleaseEntry> pressureReleases;

  const SedentaryArcData(this.bouts, this.pressureReleases);
}

final sedentaryArcProvider =
    FutureProvider.family<SedentaryArcData, Pagination>(
        (ref, pagination) async {
  final bouts = await ref.watch(boutsProvider(pagination).future);
  // TODO: fix this
  // final journal = await ref.watch(journalProvider(pagination).future);

  return SedentaryArcData(
    bouts.where((e) => e.activity == Activity.sedentary).toList(),
    [],
    // journal.whereType<PressureReleaseEntry>().toList(),
  );
});

class SedentaryArc extends ConsumerWidget {
  final Pagination pagination;

  const SedentaryArc(this.pagination, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(sedentaryArcProvider(pagination)).when(
          data: (data) => ActivityArc(
            bouts: data.bouts,
            journalEntries: data.pressureReleases,
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
