import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/screens/detail/sedentary.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/goal_widget.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:scimovement/widgets/stat_widget.dart';

class PressureReleaseScreen extends ConsumerWidget {
  const PressureReleaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagination = ref.watch(paginationProvider);

    return DetailScreen(
        title: 'Tryckavlastning',
        pageBuilder: (ctx, page) => pagination.mode == ChartMode.day
            ? SedentaryArc(Pagination(mode: pagination.mode, page: page))
            : SedentaryBarChart(Pagination(mode: pagination.mode, page: page)),
        header: StatHeader(
          provider: pressureReleaseCountProvider(pagination),
          unit: Unit.amount,
        ),
        content: Column(
          children: [
            _goalWidget(context, ref, pagination),
            // InfoBox(title: 'a', text: 'o'),
          ],
        ));
  }

  Widget _goalWidget(BuildContext context, WidgetRef ref, pagination) {
    return ref.watch(journalGoalProvider(pagination)).when(
          data: (goal) {
            if (goal != null) {
              return GoalWidget(goal: goal);
            }
            return Column(
              children: [
                Button(
                  width: 160,
                  onPressed: () => context.goNamed('edit-goal'),
                  title: 'Skapa ditt mål',
                ),
              ],
            );
          },
          error: (_, __) => Container(),
          loading: () => Container(),
        );
  }
}
