import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/screens/journal/pain_slider.dart';
import 'package:scimovement/widgets/text_field.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: AppTheme.screenPadding,
      children: [
        AppTheme.separator,
        const CreateJournal(),
        AppTheme.separator,
        const JournalChart(),
        AppTheme.separator,
        const JournalList()
      ],
    );
  }
}

class JournalList extends ConsumerWidget {
  const JournalList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(journalProvider).when(
          data: (data) => _buildList(data, ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text(e.toString()),
        );
  }

  Widget _buildList(List<JournalEntry> data, WidgetRef ref) {
    return ListView(
      shrinkWrap: true,
      children: data
          .map(
            (e) => GestureDetector(
              onTap: () => ref
                  .read(updateJournalProvider.notifier)
                  .deleteJournalEntry(e.id),
              child: ListTile(
                title: Text(e.time.toString()),
                subtitle: Text('${e.comment} - ${e.painLevel}'),
              ),
            ),
          )
          .toList(),
    );
  }
}

class CreateJournal extends ConsumerWidget {
  const CreateJournal({Key? key}) : super(key: key);

  FormGroup buildForm() => fb.group({
        'painLevel': FormControl<int>(
          value: 0,
          validators: [
            Validators.required,
            Validators.min(0),
            Validators.max(10)
          ],
        ),
        'comment': FormControl<String>(
          value: '',
        ),
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReactiveFormBuilder(
      form: buildForm,
      builder: (context, form, _) {
        return Column(
          children: [
            const StyledTextField(
              formControlName: 'comment',
              placeholder: 'comment',
            ),
            AppTheme.spacer2x,
            PainSlider(formKey: 'painLevel'),
            Button(
              width: 160,
              onPressed: () async {
                String comment = form.value['comment'] as String;
                int painLevel = form.value['painLevel'] as int;
                await ref
                    .read(updateJournalProvider.notifier)
                    .createJournalEntry(comment, painLevel);
                form.reset();
              },
              title: 'Create entry',
            ),
          ],
        );
      },
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
