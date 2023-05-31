import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/theme/theme.dart';

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
              Text('Välj övningar', style: AppTheme.labelLarge),
              Text(
                'Tänk på att fullständing tryckavlastning ger bäst resultat.',
                style: AppTheme.paragraphMedium,
              ),
              AppTheme.spacer2x,
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _exerciseItem(state, PressureReleaseExercise.forwards),
                  _exerciseItem(state, PressureReleaseExercise.rightSide),
                  _exerciseItem(state, PressureReleaseExercise.leftSide),
                ],
              ),
              AppTheme.spacer2x,
            ],
          )),
    );
  }

  void _onTap(state, PressureReleaseExercise exercise) {
    if (state.value.contains(exercise)) {
      state.value.remove(exercise);
    } else {
      state.value.add(exercise);
    }
    form.patchValue({
      'exercises': state.value,
    });
  }

  Widget _exerciseItem(state, PressureReleaseExercise exercise) {
    bool selected = state.value.contains(exercise);
    return GestureDetector(
      onTap: () {
        _onTap(state, exercise);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color:
                selected ? AppTheme.colors.success : AppTheme.colors.lightGray,
            width: 2,
          ),
        ),
        width: 100,
        height: 100,
        child: Center(child: Text(exercise.name.toString())),
      ),
    );
  }
}
