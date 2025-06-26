import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class PressureReleaseExerciseSelect extends HookWidget {
  final FormGroup form;

  const PressureReleaseExerciseSelect({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<List<PressureReleaseExercise>> state = useState(
      form.control('exercises').value ??
          [
            PressureReleaseExercise.forwards,
            PressureReleaseExercise.rightSide,
            PressureReleaseExercise.leftSide,
          ],
    );

    return ReactiveFormConsumer(
      builder: ((context, formGroup, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.pressureReleaseSelectExercises,
                style: AppTheme.labelLarge,
              ),
              Text(
                AppLocalizations.of(context)!
                    .pressureReleaseSelectExercisesDescription,
                style: AppTheme.paragraphMedium,
              ),
              AppTheme.spacer2x,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .pressureReleaseSittingExercises,
                    style: AppTheme.labelMedium,
                  ),
                  AppTheme.spacer,
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _exerciseItem(
                          context, state, PressureReleaseExercise.forwards),
                      _exerciseItem(
                          context, state, PressureReleaseExercise.rightSide),
                      _exerciseItem(
                          context, state, PressureReleaseExercise.leftSide),
                    ],
                  ),
                ],
              ),
              AppTheme.spacer2x,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.pressureReleaseExerciseLying,
                    style: AppTheme.labelMedium,
                  ),
                  AppTheme.spacer,
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _exerciseItem(
                          context, state, PressureReleaseExercise.lying),
                    ],
                  ),
                ],
              ),
              AppTheme.spacer2x,
            ],
          )),
    );
  }

  void _onTap(state, PressureReleaseExercise exercise) {
    if (exercise == PressureReleaseExercise.lying) {
      state.value = [PressureReleaseExercise.lying];
      form.patchValue({
        'exercises': state.value,
      });
      return;
    }

    if (state.value.contains(PressureReleaseExercise.lying)) {
      state.value.remove(PressureReleaseExercise.lying);
    }

    if (state.value.contains(exercise)) {
      state.value.remove(exercise);
    } else {
      state.value.add(exercise);
    }
    form.patchValue({
      'exercises': state.value,
    });
  }

  Widget _exerciseItem(
      BuildContext context, state, PressureReleaseExercise exercise) {
    bool selected = state.value.contains(exercise);
    return Opacity(
      opacity: selected ? 1 : 0.5,
      child: GestureDetector(
        onTap: () {
          _onTap(state, exercise);
        },
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected
                      ? AppTheme.colors.success
                      : AppTheme.colors.lightGray,
                  width: 4,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              width: 90,
              height: 90,
              child: Image.asset(exercise.asset),
            ),
            AppTheme.spacer,
            Text(exercise.displayString(context)),
          ],
        ),
      ),
    );
  }
}
