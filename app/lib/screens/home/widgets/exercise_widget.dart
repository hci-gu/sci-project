import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final exerciseWidgetProvider = FutureProvider<WidgetValues>((ref) async {
  List<Bout> previous =
      await ref.watch(excerciseBoutsProvider(const Pagination(page: 7)).future);
  List<Bout> current =
      await ref.watch(excerciseBoutsProvider(const Pagination()).future);
  return WidgetValues(current.length, previous.length);
});

class ExerciseWidget extends ConsumerWidget {
  const ExerciseWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String asset = 'assets/svg/exercise.svg';
    return GestureDetector(
      onTap: () => context.goNamed('exercise'),
      child: ref.watch(exerciseWidgetProvider).when(
            data: (WidgetValues values) => StatWidget(
              title: AppLocalizations.of(context)!.workout,
              values: values,
              unit: Unit.amount,
              asset: asset,
              mode: StatWidgetMode.week,
            ),
            error: (_, __) => StatWidget.error(asset),
            loading: () => StatWidget.loading(asset),
          ),
    );
  }
}
