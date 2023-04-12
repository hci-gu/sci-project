import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:go_router/go_router.dart';

final exerciseWidgetProvider = FutureProvider<WidgetValues>((ref) async {
  List<Bout> bouts = await ref.watch(excerciseBoutsProvider.future);
  return WidgetValues(bouts.length, 0);
});

class ExerciseWidget extends ConsumerWidget {
  const ExerciseWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String asset = 'assets/svg/exercise.svg';
    return GestureDetector(
      onTap: () {
        String path = GoRouter.of(context).location;
        context.go('$path${path.length > 1 ? '/' : ''}exercise');
      },
      child: ref.watch(exerciseWidgetProvider).when(
            data: (WidgetValues values) => StatWidget(
              title: 'Träningspass',
              values: values,
              unit: Unit.amount,
              asset: asset,
              mode: StatWidgetMode.week,
              action: Button(
                width: 100,
                icon: Icons.add,
                onPressed: () {
                  String path = GoRouter.of(context).location;
                  context.go(
                    '$path${path.length > 1 ? '/' : ''}exercise',
                    extra: true,
                  );
                },
                size: ButtonSize.tiny,
                title: 'Lägg till',
              ),
            ),
            error: (_, __) => StatWidget.error(asset),
            loading: () => StatWidget.loading(asset),
          ),
    );
  }
}
