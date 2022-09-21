import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/charts/activity_line_chart.dart';
import 'package:scimovement/widgets/charts/energy_bar_chart.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:scimovement/widgets/stat_widget.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination page = ref.watch(paginationProvider);

    return DetailScreen(
      title: 'Rörelse',
      header: StatHeader(
        unit: Unit.time,
        averageProvider: averageMovementMinutesProvider(page),
        totalProvider: totalMovementMinutesProvider(page),
      ),
      body: Column(
        children: [
          AppTheme.separator,
          _isDay(ref)
              ? const ActivityLineChart(isCard: false)
              : const EnergyBarChart(displayMode: BarChartDisplayMode.activity),
          AppTheme.separator,
        ],
      ),
    );
  }

  bool _isDay(WidgetRef ref) {
    return ref.watch(paginationProvider).mode == ChartMode.day;
  }
}
