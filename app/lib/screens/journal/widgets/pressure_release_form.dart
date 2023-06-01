import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/screens/journal/widgets/pressure_release_exercise_select.dart';

class PressureReleaseForm extends StatelessWidget {
  final FormGroup form;

  const PressureReleaseForm({
    super.key,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PressureReleaseExerciseSelect(form: form),
      ],
    );
  }

  static buildForm(
      PressureReleaseEntry? pressureReleaseEntry, bool shouldCreateEntry) {
    List<PressureReleaseExercise> exercises = [
      PressureReleaseExercise.leftSide,
      PressureReleaseExercise.rightSide,
      PressureReleaseExercise.forwards,
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
