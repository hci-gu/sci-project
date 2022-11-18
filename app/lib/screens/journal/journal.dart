import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/screens/journal/widgets/pain_slider.dart';
import 'package:scimovement/widgets/text_field.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: AppTheme.screenPadding,
      children: [
        AppTheme.separator,
        const JournalChart(),
        AppTheme.separator,
        const JournalList(),
        AppTheme.separator,
        Button(
            title: 'Create',
            onPressed: () => GoRouter.of(context).goNamed('create-journal'))
      ],
    );
  }
}

class JournalList extends ConsumerWidget {
  const JournalList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(uniqueEntriesProvider).when(
          data: (data) => _buildList(context, data, ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text(e.toString()),
        );
  }

  Widget _buildList(
      BuildContext context, List<JournalEntry> data, WidgetRef ref) {
    return ListView(
      shrinkWrap: true,
      children: data
          .map(
            (e) => GestureDetector(
              onTap: () => GoRouter.of(context).goNamed(
                'create-journal',
                extra: {
                  'bodyPart': e.bodyPart,
                  'arm': e.arm,
                },
              ),
              child: ListTile(
                title: Text(
                    '${e.arm != null ? '${e.arm!.displayString()} ' : ''}${e.bodyPart.displayString()}'),
                subtitle: Text(e.time.toIso8601String()),
              ),
            ),
          )
          .toList(),
    );
  }
}

class JournalChart extends ConsumerWidget {
  const JournalChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(journalProvider).when(
          data: (data) => _buildChart(data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text(e.toString()),
        );
  }

  Widget _buildChart(List<JournalEntry> data) {
    if (data.isEmpty) {
      return Container();
    }

    double minX = data.first.time.millisecondsSinceEpoch.toDouble();
    double maxX = data.last.time.millisecondsSinceEpoch.toDouble();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(
            show: false,
          ),
          gridData: FlGridData(
            show: false,
          ),
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .map(
                    (e) => FlSpot(
                      e.time.millisecondsSinceEpoch.toDouble(),
                      e.painLevel.toDouble(),
                    ),
                  )
                  .toList(),
              preventCurveOverShooting: true,
              barWidth: 2,
              isCurved: false,
              color: AppTheme.colors.primary,
              dotData: FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, _) {
                  if (value == minX || value == maxX) return const SizedBox();
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Center(
                    child: Text(
                      DateFormat('HH:mm').format(date),
                      style: AppTheme.labelTiny,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
