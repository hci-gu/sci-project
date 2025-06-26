import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/screens/journal/widgets/forms/pressure_release_exercise_select.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class PressureReleaseForm extends StatelessWidget {
  final FormGroup form;
  final bool shouldCreateEntry;

  const PressureReleaseForm({
    super.key,
    required this.form,
    this.shouldCreateEntry = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PressureReleaseExerciseSelect(form: form),
      ],
    );
  }

  static Widget actions(
      BuildContext context, FormGroup form, Function callback) {
    return Column(
      children: [
        Button(
          secondary: true,
          width: 200,
          onPressed: () {
            callback(true, true);
          },
          title: AppLocalizations.of(context)!.save,
        ),
        Text(
          AppLocalizations.of(context)!.pressureReleaseAlreadyDone,
          style: AppTheme.paragraphSmall,
        ),
        AppTheme.spacer2x,
        ReactiveFormConsumer(
          builder: ((context, formGroup, child) {
            List<PressureReleaseExercise> exercises =
                formGroup.value['exercises'] as List<PressureReleaseExercise>;
            if (exercises.contains(PressureReleaseExercise.lying) ||
                exercises.isEmpty) {
              return const SizedBox.shrink();
            }

            return Button(
              width: 200,
              onPressed: () {
                context.goNamed('perform-pressure-release', extra: {
                  'exercises': exercises,
                });

                callback(false, false);
              },
              title: AppLocalizations.of(context)!.start,
            );
          }),
        ),
      ],
    );
  }

  static buildForm(
      PressureReleaseEntry? pressureReleaseEntry, bool shouldCreateEntry) {
    List<PressureReleaseExercise> exercises = [
      PressureReleaseExercise.forwards,
      PressureReleaseExercise.leftSide,
      PressureReleaseExercise.rightSide,
    ];

    if (!shouldCreateEntry && pressureReleaseEntry != null) {
      exercises = pressureReleaseEntry.exercises;
    }

    return {
      'exercises': FormControl<List<PressureReleaseExercise>>(
        value: exercises,
      ),
    };
  }
}
