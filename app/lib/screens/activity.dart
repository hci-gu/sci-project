import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/chart_mode_select.dart';
import 'package:scimovement/widgets/charts/energy_bar_chart.dart';
import 'package:scimovement/widgets/charts/energy_line_chart.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:scimovement/widgets/stat_widget.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination page = ref.watch(paginationProvider);

    return Scaffold(
      appBar: AppTheme.appBar('Rörelse'),
      body: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatHeader(
                  unit: Unit.sedentary,
                  averageProvider: averageMovementMinutesProvider(page),
                  totalProvider: totalMovementMinutesProvider(page),
                ),
                const ChartModeSelect()
              ],
            ),
            _separator(),
            _isDay(ref)
                ? const EnergyLineChart(isCard: false)
                : const EnergyBarChart(displayCalories: false),
            _separator(),
          ],
        ),
      ),
    );
  }

  bool _isDay(WidgetRef ref) {
    return ref.watch(paginationProvider).mode == ChartMode.day;
  }

  Widget _separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        height: 1,
        color: const Color.fromRGBO(0, 0, 0, 0.1),
      ),
    );
  }
}
