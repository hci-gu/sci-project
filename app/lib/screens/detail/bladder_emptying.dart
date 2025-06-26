import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/screens/detail/sedentary.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/goal_widget.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class BladderEmptyingScreen extends ConsumerWidget {
  const BladderEmptyingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagination = ref.watch(paginationProvider);

    return DetailScreen(
        title: AppLocalizations.of(context)!.bladderEmptying,
        pageBuilder: (ctx, page) => pagination.mode == ChartMode.day
            ? SedentaryArc(
                Pagination(mode: pagination.mode, page: page),
                type: JournalType.bladderEmptying,
              )
            : SedentaryBarChart(Pagination(mode: pagination.mode, page: page)),
        header: StatHeader(
          provider: bladderEmptyingCountProvider(pagination),
          unit: Unit.amount,
          isAverage: false,
        ),
        content: Column(
          children: [
            _goalWidget(context, ref),
            AppTheme.separator,
            Button(
              icon: Icons.alarm,
              width: 200,
              onPressed: () => context.pushNamed(
                'create-journal',
                extra: {
                  'type': JournalType.bladderEmptying,
                },
              ),
              title: AppLocalizations.of(context)!.bladderEmptying,
            )
          ],
        ));
  }

  Widget _goalWidget(BuildContext context, WidgetRef ref) {
    return ref.watch(bladderEmptyingGoalProvider).when(
          data: (goal) {
            if (goal != null) {
              return GoalWidget(goal: goal, type: JournalType.bladderEmptying);
            }
            return Column(
              children: [
                Button(
                  width: 160,
                  onPressed: () => context.goNamed('edit-goal-bladder', extra: {
                    'type': JournalType.bladderEmptying,
                  }),
                  title: AppLocalizations.of(context)!.createYourGoal,
                ),
              ],
            );
          },
          error: (_, __) => Container(),
          loading: () => Container(),
        );
  }
}
