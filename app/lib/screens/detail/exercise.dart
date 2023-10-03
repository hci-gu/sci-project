import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/exercise.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/detail/screen.dart';
import 'package:scimovement/screens/detail/sedentary.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_arc/activity_arc.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/charts/chart_wrapper.dart';
import 'package:scimovement/widgets/goal_widget.dart';
import 'package:scimovement/widgets/stat_header.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final exerciseArcProvider =
    FutureProvider.family<List<Bout>, Pagination>((ref, pagination) async {
  final bouts = await ref.watch(boutsProvider(pagination).future);

  return bouts
      .where((e) => e.activity == Activity.active || e.activity.isExercise)
      .toList();
});

class ExerciseArc extends ConsumerWidget {
  final Pagination pagination;

  const ExerciseArc(this.pagination, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(exerciseArcProvider(pagination)).when(
          data: (data) => ActivityArc(
            bouts: data,
            activities: const [Activity.active, Activity.moving],
          ),
          error: (e, stacktrace) => ChartWrapper.error(e.toString()),
          loading: () => ChartWrapper.loading(),
        );
  }
}

class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagination = ref.watch(paginationProvider);

    return DetailScreen(
        title: AppLocalizations.of(context)!.exercise,
        pageBuilder: (ctx, page) => ExerciseArc(
              Pagination(mode: pagination.mode, page: page),
            ),
        header: StatHeader(
          provider: exerciseCountProvider(pagination),
          unit: Unit.amount,
          isAverage: false,
        ),
        showModeSelect: false,
        content: Column(
          children: [
            Button(
              icon: Icons.offline_bolt_outlined,
              width: 200,
              onPressed: () => context.pushNamed(
                'create-journal',
                extra: {
                  'type': JournalType.exercise,
                },
              ),
              title: AppLocalizations.of(context)!.newExercise,
            )
          ],
        ));
  }
}
