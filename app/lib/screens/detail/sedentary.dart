import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/sedentary.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/charts/activity_line_chart.dart';
import 'package:scimovement/widgets/charts/energy_bar_chart.dart';
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
        averageProvider: averageSedentaryMinutesProvider(pagination),
        totalProvider: totalSedentaryMinutesProvider(pagination),
      ),
      pageBuilder: (ctx, page) => EnergyBarChart(
        displayMode: BarChartDisplayMode.sedentary,
        pagination: Pagination(page: page, mode: pagination.mode),
      ),
    );
  }
}